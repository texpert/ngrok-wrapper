# frozen_string_literal: true

require_relative 'wrapper/version'
require 'tempfile'

module Ngrok
  OPTIONAL_PARAMS = %i[authtoken bind_tls host_header hostname inspect region subdomain].freeze

  class NotFound < StandardError; end
  class FetchUrlError < StandardError; end
  class Error < StandardError; end

  class Wrapper
    class << self
      attr_reader :pid, :ngrok_url, :ngrok_url_https, :status, :params

      def init(params = {})
        # map old key 'port' to 'addr' to maintain backwards compatibility with versions 2.0.21 and earlier
        params[:addr] = params.delete(:port) if params.key?(:port)

        @params = { addr: 3001, timeout: 10, config: '/dev/null' }.merge!(params)
        @status ||= :stopped # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      def start(params = {})
        ensure_binary
        init(params)

        persistent_ngrok = @params[:persistence] == true
        # Attempt to read the attributes of an existing process instead of starting a new process.
        try_params_from_running_ngrok if persistent_ngrok

        spawn_new_ngrok(persistent_ngrok: persistent_ngrok) if stopped?

        @status = :running
        if persistent_ngrok
          # Record the attributes of the new process so that it can be reused on a subsequent call.
          File.write(@persistence_file, { pid: @pid, ngrok_url: @ngrok_url, ngrok_url_https: @ngrok_url_https }.to_json)
        end

        @ngrok_url
      end

      def stop
        if running?
          Process.kill(9, @pid)
          @ngrok_url = @ngrok_url_https = @pid = nil
          @status = :stopped
        end
        @status
      end

      def running?
        @status == :running
      end

      def stopped?
        @status == :stopped
      end

      def addr
        @params[:addr]
      end

      def port
        return addr if addr.is_a?(Numeric)

        addr.split(':').last.to_i
      end

      def inherited(subclass)
        super
        init
      end

      private

      def parse_persistence_file
        JSON.parse(File.read(@persistence_file))
      rescue StandardError => _e # Catch all possible errors on reading and parsing the file
        nil
      end

      def raise_if_similar_ngroks(pid)
        other_similar_ngroks = ngrok_process_status_lines.select do |line|
          # If the pid is not nil and the line starts with this pid, do not take this line into account
          !(pid && line.start_with?(pid)) && line.include?('ngrok http') && line.end_with?(addr.to_s)
        end

        return if other_similar_ngroks.empty?

        raise Ngrok::Error, "ERROR: Other ngrok instances tunneling to port #{addr} found"
      end

      def ngrok_process_status_lines(refetch: false)
        return @ngrok_process_status_lines if defined?(@ngrok_process_status_lines) && !refetch

        @ngrok_process_status_lines = (`ps ax | grep "ngrok http"`).split("\n")
      end

      def try_params_from_running_ngrok
        @persistence_file = @params[:persistence_file] || "#{File.dirname(@params[:config])}/ngrok-process.json"
        state = parse_persistence_file
        pid = state&.[]('pid')
        raise_if_similar_ngroks(pid)

        return unless ngrok_running?(pid)

        @status = :running
        @pid = pid
        @ngrok_url = state['ngrok_url']
        @ngrok_url_https = state['ngrok_url_https']
      end

      def ngrok_running?(pid)
        pid && Process.kill(0, pid.to_i) ? true : false
      rescue Errno::ESRCH, Errno::EPERM
        false
      end

      def spawn_new_ngrok(persistent_ngrok:)
        raise_if_similar_ngroks(nil)
        # Prepare the log file into which ngrok output will be redirected in `ngrok_exec_params`
        @params[:log] = @params[:log] ? File.open(@params[:log], 'w+') : Tempfile.new('ngrok')
        if persistent_ngrok
          Process.spawn("exec nohup ngrok http #{ngrok_exec_params} &")
          @pid = ngrok_process_status_lines(refetch: true).find { |line| line.include?('ngrok http -log') }.split[0]
        else
          @pid = Process.spawn("exec ngrok http #{ngrok_exec_params}")
          at_exit { Ngrok::Wrapper.stop }
        end

        fetch_urls
      end

      def ngrok_exec_params
        exec_params = +'-log=stdout -log-level=debug '
        OPTIONAL_PARAMS.each do |opt|
          exec_params << "-#{opt.to_s.tr('_', '-')}=#{@params[opt]} " if @params.key?(opt)
        end
        exec_params << "-config #{@params[:config]} #{@params[:addr]} > #{@params[:log].path}"
      end

      def fetch_urls
        @params[:timeout].times do
          log_content = @params[:log].read
          result = log_content.scan(/URL:(.+)\sProto:(http|https)\s/)
          unless result.empty?
            result           = Hash[*result.flatten].invert
            @ngrok_url       = result['http']
            @ngrok_url_https = result['https']
            break if @ngrok_url || @ngrok_url_https
          end

          @error = log_content.scan(/msg="command failed" err="([^"]+)"/).flatten
          break unless @error.empty?

          sleep 1
          @params[:log].rewind
        end

        @params[:log].close
        return if @ngrok_url || @ngrok_url_https

        stop
        raise FetchUrlError, 'Unable to fetch external url' if @error.empty?

        raise Ngrok::Error, @error.first
      end

      def ensure_binary
        `ngrok version`
      rescue Errno::ENOENT
        raise Ngrok::NotFound, 'Ngrok binary not found'
      end
    end

    init
  end
end
