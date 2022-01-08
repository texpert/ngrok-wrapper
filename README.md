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
                    config: '~/.ngrok',
                    persistence: true,
                    persistence_file: '/Users/user/.ngrok2/ngrok-process.json') # optional parameter

```

### With Rails (Rack server)

See [examples/rack_server.rb](examples/rack_server.rb) and [examples/rails_server.rb](examples/rails_server.rb) to get an idea how to use it along with a Rack or Rails server so that it automatically starts and stops when the server does.


## Contributing

1. Fork it ( https://github.com/texpert/ngrok-wrapper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
