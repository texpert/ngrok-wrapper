# frozen_string_literal: true

# rubocop:disable RSpec/DescribedClass
RSpec.describe Ngrok::Wrapper do
  before { allow(Ngrok::Wrapper).to receive(:ensure_binary) }

  it 'has a version number' do
    expect(Ngrok::Wrapper::VERSION).not_to be nil
  end

  describe 'Before start' do
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
    before(:all) { Ngrok::Wrapper.start } # rubocop:disable RSpec/BeforeAfterAll

    after(:all)  { Ngrok::Wrapper.stop } # rubocop:disable RSpec/BeforeAfterAll

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
    it 'uses custom log file' do
      Ngrok::Wrapper.start(log: 'test.log')
      expect(Ngrok::Wrapper.running?).to eq true
      expect(Ngrok::Wrapper.log.path).to eq 'test.log'
      Ngrok::Wrapper.stop
      expect(Ngrok::Wrapper.stopped?).to eq true
    end
  end

  describe 'Custom subdomain' do
    it 'fails without authtoken' do
      expect { Ngrok::Wrapper.start(subdomain: 'test-subdomain') }.to raise_error Ngrok::Error
    end

    it 'fails with incorrect authtoken' do
      expect do
        Ngrok::Wrapper.start(subdomain: 'test-subdomain', authtoken: 'incorrect_token')
      end.to raise_error Ngrok::Error
    end
  end

  describe 'Custom hostname' do
    it 'fails without authtoken' do
      expect { Ngrok::Wrapper.start(hostname: 'example.com') }.to raise_error Ngrok::Error
    end

    it 'fails with incorrect authtoken' do
      expect { Ngrok::Wrapper.start(hostname: 'example.com', authtoken: 'incorrect_token') }.to raise_error Ngrok::Error
    end
  end

  describe 'Custom addr' do
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
    before { allow(Process).to receive(:kill) }

    after { Ngrok::Wrapper.stop }

    describe 'when persistence param is true' do
      it 'tries fetching params of an already running Ngrok and store Ngrok process data into a file' do
        expect(Ngrok::Wrapper).to receive(:try_params_from_running_ngrok)
        expect(Ngrok::Wrapper).to receive(:spawn_new_ngrok).with(persistent_ngrok: true)
        expect(Ngrok::Wrapper).to receive(:store_new_ngrok_process)

        Ngrok::Wrapper.start(persistence: true)
      end
    end

    describe 'when persistence param is not true' do
      it "doesn't try to fetch params of an already running Ngrok" do
        expect(Ngrok::Wrapper).not_to receive(:try_params_from_running_ngrok)
        expect(Ngrok::Wrapper).to receive(:spawn_new_ngrok).with(persistent_ngrok: false)
        expect(Ngrok::Wrapper).not_to receive(:store_new_ngrok_process)

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
# rubocop:enable RSpec/DescribedClass
