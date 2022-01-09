# frozen_string_literal: true

RSpec.describe 'Ngrok::Wrapper' do
  let(:log) { File.read("#{RSPEC_ROOT}/fixtures/ngrok.sample.log") }
  let(:fake_pid) { rand(99_999) }

  before do
    allow(Ngrok::Wrapper).to receive(:ensure_binary)
    allow(Ngrok::Wrapper).to receive(:raise_if_similar_ngroks)
    allow(Process).to receive(:spawn).and_return(fake_pid)
    allow(Process).to receive(:kill)
  end

  it 'has a version number' do
    expect(Ngrok::Wrapper::VERSION).not_to be nil
  end

  describe 'Before start' do
    before { allow_any_instance_of(Tempfile).to receive(:read).and_return(log) }

    it 'is not running' do
      expect(Ngrok::Wrapper.running?).to be false
    end

    it 'is stopped' do
      expect(Ngrok::Wrapper.stopped?).to be true
    end

    it 'has :stopped status' do
      expect(Ngrok::Wrapper.status).to eq :stopped
    end
  end

  describe 'After start' do
    before do
      allow_any_instance_of(Tempfile).to receive(:read).and_return(log)

      Ngrok::Wrapper.start
    end

    after { Ngrok::Wrapper.stop }

    it 'is running' do
      expect(Ngrok::Wrapper.running?).to be true
    end

    it 'is not stopped' do
      expect(Ngrok::Wrapper.stopped?).to be false
    end

    it 'has :running status' do
      expect(Ngrok::Wrapper.status).to eq :running
    end

    it 'has correct port property' do
      expect(Ngrok::Wrapper.port).to eq(3001)
    end

    it 'has correct addr property' do
      expect(Ngrok::Wrapper.addr).to eq(3001)
    end

    it 'has valid ngrok_url' do
      expect(Ngrok::Wrapper.ngrok_url).to be =~ %r{http://.*ngrok\.io$}
    end

    it 'has valid ngrok_url_https' do
      expect(Ngrok::Wrapper.ngrok_url_https).to be =~ %r{https://.*ngrok\.io$}
    end

    it 'has correct pid property' do
      expect(Ngrok::Wrapper.pid).to be > 0
    end
  end

  describe 'Custom log file' do
    before { allow_any_instance_of(File).to receive(:read).and_return(log) }

    it 'uses custom log file' do
      Ngrok::Wrapper.start(log: 'test.log')
      expect(Ngrok::Wrapper.running?).to eq true
      expect(Ngrok::Wrapper.params[:log].path).to eq 'test.log'
      Ngrok::Wrapper.stop
      expect(Ngrok::Wrapper.stopped?).to eq true
    end
  end

  describe 'Invalid or missing authtoken' do
    describe 'when no authtoken is specified in ngrok config file' do
      let(:no_auth_log) { File.read("#{RSPEC_ROOT}/fixtures/ngrok.no_auth_token.log") }

      it 'raises Ngrok::Error exception' do
        allow_any_instance_of(Tempfile).to receive(:read).and_return(no_auth_log)

        expect { Ngrok::Wrapper.start }.to raise_error Ngrok::Error
      end
    end

    describe 'when an invalid authtoken is specified in ngrok config file' do
      let(:invalid_auth_log) { File.read("#{RSPEC_ROOT}/fixtures/ngrok.no_auth_token.log") }

      it 'fails with incorrect authtoken' do
        allow_any_instance_of(Tempfile).to receive(:read).and_return(invalid_auth_log)

        expect do
          Ngrok::Wrapper.start(authtoken: 'incorrect_token')
        end.to raise_error Ngrok::Error
      end
    end
  end

  describe 'Custom addr' do
    before { allow_any_instance_of(Tempfile).to receive(:read).and_return(log) }

    it 'maps port param to addr' do
      port = 10_010
      Ngrok::Wrapper.start(port: port)
      expect(Ngrok::Wrapper.addr).to eq port
      Ngrok::Wrapper.stop
    end

    it 'returns just the port when the address contains a host' do
      addr = '192.168.0.5:10010'
      Ngrok::Wrapper.start(addr: addr)
      expect(Ngrok::Wrapper.port).to eq 10_010
      Ngrok::Wrapper.stop
    end

    it 'supports remote addresses' do
      addr = '192.168.0.5:10010'
      Ngrok::Wrapper.start(addr: addr)
      expect(Ngrok::Wrapper.addr).to eq addr
      Ngrok::Wrapper.stop
    end
  end

  describe 'Custom region' do
    before { allow_any_instance_of(Tempfile).to receive(:read).and_return(log) }

    it "doesn't include the -region parameter when it is not provided" do
      Ngrok::Wrapper.start
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).not_to include('-region=')
      Ngrok::Wrapper.stop
    end

    it 'includes the -region parameter with the correct value when it is provided' do
      region = 'eu'
      Ngrok::Wrapper.start(region: region)
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).to include("-region=#{region}")
      Ngrok::Wrapper.stop
    end
  end

  describe 'Custom bind-tls' do
    before { allow_any_instance_of(Tempfile).to receive(:read).and_return(log) }

    it "doesn't include the -bind-tls parameter when it is not provided" do
      Ngrok::Wrapper.start
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).not_to include('-bind-tls=')
      Ngrok::Wrapper.stop
    end

    it 'includes the -bind-tls parameter with the correct value when it is true' do
      bind_tls = true
      Ngrok::Wrapper.start(bind_tls: bind_tls)
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).to include("-bind-tls=#{bind_tls}")
      Ngrok::Wrapper.stop
    end

    it 'includes the -bind-tls parameter with the correct value when it is false' do
      bind_tls = false
      Ngrok::Wrapper.start(bind_tls: bind_tls)
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).to include("-bind-tls=#{bind_tls}")
      Ngrok::Wrapper.stop
    end
  end

  describe 'Custom host header' do
    after { Ngrok::Wrapper.stop }

    it "doesn't include the -host-header parameter when it is not provided" do
      expect(Ngrok::Wrapper).to receive(:fetch_urls)
      Ngrok::Wrapper.start
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).not_to include('-host-header=')
    end

    it 'includes the -host-header parameter with the correct value when it is provided' do
      expect(Ngrok::Wrapper).to receive(:fetch_urls)
      host_header = 'foo.bar'
      Ngrok::Wrapper.start(host_header: host_header)
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).to include("-host-header=#{host_header}")
    end
  end

  describe 'Custom parameters provided' do
    before { allow_any_instance_of(Tempfile).to receive(:read).and_return(log) }

    it "doesn't include the -inspect parameter when it is not provided" do
      Ngrok::Wrapper.start
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).not_to include('-inspect=')
      Ngrok::Wrapper.stop
    end

    it 'includes the -inspect parameter with the correct value when it is provided' do
      Ngrok::Wrapper.start(inspect: true)
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).to include('-inspect=true')
      Ngrok::Wrapper.stop

      Ngrok::Wrapper.start(inspect: false)
      expect(Ngrok::Wrapper.__send__(:ngrok_exec_params)).to include('-inspect=false')
      Ngrok::Wrapper.stop
    end
  end

  describe '#start' do
    after { Ngrok::Wrapper.stop }

    describe 'when persistence param is true' do
      before do
        allow(File).to receive(:write)
        allow(Ngrok::Wrapper).to receive(:try_params_from_running_ngrok).and_call_original
        allow(Ngrok::Wrapper).to receive(:parse_persistence_file).and_return(state)
      end

      describe 'tries fetching params of an already running Ngrok and store Ngrok process data into a file' do
        describe 'when fetching params returns nil' do
          let(:state) { nil }

          it "doesn't check for similar ngroks running" do
            expect(Ngrok::Wrapper).to receive(:try_params_from_running_ngrok)
            expect(Ngrok::Wrapper).not_to receive(:raise_if_similar_ngroks)
            expect(Ngrok::Wrapper).not_to receive(:ngrok_running?)
            expect(Ngrok::Wrapper).to receive(:spawn_new_ngrok).with(persistent_ngrok: true)
            expect(File).to receive(:write)

            Ngrok::Wrapper.start(persistence: true)
          end
        end

        describe 'when fetching params returns a legit hash' do
          let(:state) do
            { 'pid'             => '795',
              'ngrok_url'       => 'http://b1cd-109-185-141-9.ngrok.io',
              'ngrok_url_https' => 'https://b1cd-109-185-141-9.ngrok.io'}
          end

          describe 'checking if a similar Ngrok is running' do
            before do
              allow(Ngrok::Wrapper).to receive(:raise_if_similar_ngroks).and_call_original
              allow(Ngrok::Wrapper).to receive(:ngrok_process_status_lines).and_return(ngrok_ps_lines)

              expect(Ngrok::Wrapper).to receive(:try_params_from_running_ngrok)
            end

            describe 'when Ngrok process with params from the persisted file is running' do
              let(:ngrok_ps_lines) do
                ['795 ??  S   0:04.81 ngrok http -log -config /Users/thunder/.ngrok2/ngrok.yml https://localhost:3001']
              end

              it 'set Ngrok::Wrapper pid and status attributes' do
                expect(Ngrok::Wrapper).not_to receive(:spawn_new_ngrok)

                Ngrok::Wrapper.start(persistence: true)

                expect(Ngrok::Wrapper.pid).to eql('795')
                expect(Ngrok::Wrapper.status).to eql(:running)
                expect(Ngrok::Wrapper.ngrok_url).to eql('http://b1cd-109-185-141-9.ngrok.io')
                expect(Ngrok::Wrapper.ngrok_url_https).to eql('https://b1cd-109-185-141-9.ngrok.io')
              end
            end

            describe 'when a similar Ngrok with other pid is already running' do
              let(:ngrok_ps_lines) do
                ['71986 ?? S  0:04.81 ngrok http -log -config /Users/thunder/.ngrok2/ngrok.yml https://localhost:3001']
              end

              it 'raises exception' do
                expect(Ngrok::Wrapper).not_to receive(:spawn_new_ngrok)

                expect { Ngrok::Wrapper.start(persistence: true) }
                  .to raise_error(Ngrok::Error, 'ERROR: Other ngrok instances tunneling to port 3001 found')
              end
            end

            describe 'when Ngrok with the persisted pid is already running, but on a different port' do
              let(:ngrok_ps_lines) do
                ['795 ??  S   0:04.81 ngrok http -log -config /Users/thunder/.ngrok2/ngrok.yml https://localhost:3000']
              end

              it 'raises exception' do
                expect(Ngrok::Wrapper).not_to receive(:spawn_new_ngrok)

                expect { Ngrok::Wrapper.start(persistence: true) }
                  .to raise_error(Ngrok::Error, 'ERROR: Ngrok pid #795 tunneling on other port 3000')
              end
            end

            describe 'when no Ngrok process with params from the persisted file or similar is running' do
              let(:ngrok_ps_lines) do
                ['834 ??  S   0:04.81 ngrok http -log -config /Users/thunder/.ngrok2/ngrok.yml https://localhost:5001']
              end

              let(:new_ngrok_ps_lines) do
                ['835 ??  S   0:04.81 ngrok http -log -config /Users/thunder/.ngrok2/ngrok.yml https://localhost:3001']
              end

              it 'sets Ngrok::Wrapper pid and status attributes' do
                allow(Ngrok::Wrapper).to receive(:spawn_new_ngrok).with(persistent_ngrok: true).and_call_original
                allow(Ngrok::Wrapper)
                  .to receive(:ngrok_process_status_lines).with(refetch: true).and_return(new_ngrok_ps_lines)
                allow(Ngrok::Wrapper).to receive(:fetch_urls)

                expect(Ngrok::Wrapper).to receive(:spawn_new_ngrok).with(persistent_ngrok: true)
                expect(Ngrok::Wrapper)
                  .to receive(:ngrok_process_status_lines).with(refetch: true)  #.and_return(new_ngrok_ps_lines)
                allow(Ngrok::Wrapper).to receive(:fetch_urls)

                Ngrok::Wrapper.start(persistence: true)

                expect(Ngrok::Wrapper.pid).to eql('835')
                expect(Ngrok::Wrapper.status).to eql(:running)
              end
            end
          end

          it 'tries fetching params of an already running Ngrok and store Ngrok process data into a file' do
            expect(Ngrok::Wrapper).to receive(:try_params_from_running_ngrok)
            expect(Ngrok::Wrapper).to receive(:spawn_new_ngrok).with(persistent_ngrok: true)
            expect(File).to receive(:write)

            Ngrok::Wrapper.start(persistence: true)
          end
        end
      end
    end

    describe 'when persistence param is not true' do
      it "doesn't try to fetch params of an already running Ngrok" do
        expect(Ngrok::Wrapper).not_to receive(:try_params_from_running_ngrok)
        expect(Ngrok::Wrapper).to receive(:spawn_new_ngrok).with(persistent_ngrok: false)
        expect_any_instance_of(File).not_to receive(:write)

        Ngrok::Wrapper.start(persistence: false)
      end
    end

    describe 'when Ngrok::Wrapper is already running' do
      it "doesn't try to spawn a new Ngrok process" do
        allow(Ngrok::Wrapper).to receive(:stopped?).and_return(false)
        expect(Ngrok::Wrapper).not_to receive(:spawn_new_ngrok)

        Ngrok::Wrapper.start
      end
    end
  end
end
