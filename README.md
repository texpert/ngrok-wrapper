# Ngrok::Wrapper

Ngrok-wrapper gem is a ruby wrapper for ngrok v2.

[![Maintainability](https://api.codeclimate.com/v1/badges/d978e217a8219326e325/maintainability)](https://codeclimate.com/github/texpert/ngrok-wrapper/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/d978e217a8219326e325/test_coverage)](https://codeclimate.com/github/texpert/ngrok-wrapper/test_coverage)

## History

Ngrok-wrapper is renamed from my fork of the initial awesome [Ngrok-tunnel](https://github.com/bogdanovich/ngrok-tunnel) gem by [Anton Bogdanovich](https://github.com/bogdanovich)

I was dealing with debugging work on some webhooks at my current project. Using Ngrok on a free plan, I quickly got tired of Ngrok generating a new endpoint URL every time on restarting the process. 

There was a pull request [Add support for leaving an ngrok process open and reusing an existing ngrok process 
instead of starting a new one on every process](https://github.com/bogdanovich/ngrok-tunnel/pull/11), but it wasn't 
quite working. 

So, I have created [a working one](https://github.com/bogdanovich/ngrok-tunnel/pull/20), but neither 
of these PRs got any reaction from the author.

So, excuse me, [Anton Bogdanovich](https://github.com/bogdanovich), but I've decided to craft another gem, based on your awesome work, thank you!

## Installation

*Note:* You must have ngrok v2+ installed available in your `PATH`.

Add this line to your application's Gemfile:

```ruby
gem 'ngrok-wrapper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ngrok-wrapper

## Usage

```ruby
require 'ngrok/wrapper'

# spawn ngrok (default port 3001)
Ngrok::Wrapper.start

# ngrok local_port
Ngrok::Wrapper.port
=> 3001

# ngrok external url
Ngrok::Wrapper.ngrok_url
=> "http://aaa0e65.ngrok.io"

Ngrok::Wrapper.ngrok_url_https
=> "https://aaa0e65.ngrok.io"

Ngrok::Wrapper.running?
=> true

Ngrok::Wrapper.stopped?
=> false

# ngrok process id
Ngrok::Wrapper.pid
=> 27384

# ngrok log file descriptor
Ngrok::Wrapper.log
=> #<File:/tmp/ngrok20141022-27376-cmmiq4>

# kill ngrok
Ngrok::Wrapper.stop
=> :stopped

```

```ruby
# ngrok custom parameters
Ngrok::Wrapper.start(addr: 'foo.dev:80',
                    subdomain: 'MY_SUBDOMAIN',
                    hostname: 'MY_HOSTNAME',
                    authtoken: 'MY_TOKEN',
                    inspect: false,
                    log: 'ngrok.log',
                    config: '~/.ngrok2/ngrok.yml',
                    persistence: true,
                    persistence_file: '/Users/user/.ngrok2/ngrok-process.json') # optional parameter
```

- If `persistence: true` is specified, on the 1st server start, an Ngrok process will get invoked, and the attributes of this Ngrok process, like `pid`, URLs and `port` will be stored in the `persistence_file`. 
- On server stop, the Ngrok process will not be killed. 
- On the subsequent server start, Ngrok::Wrapper will read the process attributes from the `persistence_file` and will try to re-use the running Ngrok process, if it hadn't been killed.
  - The `persistence_file` parameter is optional when invoking `Ngrok::Wrapper.start`, by default the '/Users/user/.ngrok2/ngrok-process.json' will be created and used
  - The `authtoken` parameter is also optional, as long as the `config` parameter is specified (usually Ngrok config 
    is the `~/.ngrok2/ngrok.yml` file)

### With Rails

- Use ~/.ngrok2/ngrok.yml as a config file
- Set NGROK_INSPECT=false if you want to disable the inspector web-server
- Add this code at the end of `config/application.rb` in a Rails project

```ruby
NGROK_ENABLED = Rails.env.development? &&
                  (Rails.const_defined?(:Server) || ($PROGRAM_NAME.include?('puma') && Puma.const_defined?(:Server))) &&
                  ENV['NGROK_TUNNEL'] == 'true'
```

- Add the following code at the start of `config/environments/development.rb`

```ruby
if NGROK_ENABLED
  require 'ngrok/wrapper'

  options = { addr: 'https://localhost:3000', persistence: true }
  options[:config] = ENV.fetch('NGROK_CONFIG', "#{ENV['HOME']}/.ngrok2/ngrok.yml")
  options[:inspect] = ENV['NGROK_INSPECT'] if ENV['NGROK_INSPECT']

  puts "[NGROK] tunneling at #{Ngrok::Wrapper.start(options)}"
  puts '[NGROK] inspector web interface listening at http://127.0.0.1:4040' if ENV['NGROK_INSPECT'] == 'true'

  NGROK_URL = Ngrok::Wrapper.ngrok_url_https
end
```

- If you need SSL (`https`) webhooks, you can use the `localhost` gem and then, in `config/puma.rb`:

```ruby
if self.class.const_defined?(:NGROK_ENABLED)
  bind 'ssl://localhost:3000'
else
  port ENV.fetch('PORT', 3000)
end
```

- And in `config/environments/development.rb`:

```ruby
config.force_ssl = true if NGROK_ENABLED

config.action_mailer.default_url_options = {
  host: NGROK_ENABLED ? NGROK_URL.delete_prefix('https://') : 'myapp.local',
  port: 3000
}
```

- To make the sessions bound to the Ngrok domain, in `config/initializers/session_store.rb`:

```ruby
Rails.application.config.session_store :cookie_store,
  key: "_#{Rails.env}_my_app_secure_session_3",
  domain: NGROK_ENABLED ? NGROK_URL.delete_prefix('https://') : :all,
  tld_length: 2
```

- To use the webhooks when sending to, for example, Slack API, you can define the redirect URL in controller as follows:

```ruby
redirect_uri = NGROK_ENABLED ? "#{NGROK_URL}/slack/oauth/#{organization.id}" : slack_oauth_url(organization.id)
```

### With Rack server

- Use ~/.ngrok2/ngrok.yml as a config file.
- Set NGROK_INSPECT=false if you want to disable the inspector web-server.
- Add the following code to the end of a configuration file of your preferred web-server, e.g. config/puma.rb, 
config/unicorn.rb, or config/thin.rb

```ruby
require 'ngrok/wrapper'

options = { addr: 'https://localhost:3000', persistence: true }
options[:config] = ENV.fetch('NGROK_CONFIG', "#{ENV['HOME']}/.ngrok2/ngrok.yml")
options[:inspect] = ENV['NGROK_INSPECT'] if ENV['NGROK_INSPECT']

puts "[NGROK] tunneling at #{Ngrok::Wrapper.start(options)}"
puts '[NGROK] inspector web interface listening at http://127.0.0.1:4040' if ENV['NGROK_INSPECT'] == 'true'

NGROK_URL = Ngrok::Wrapper.ngrok_url_https
```

## Contributing

1. Fork it ( https://github.com/texpert/ngrok-wrapper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
