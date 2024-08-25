# Ngrok::Wrapper

Ngrok-wrapper gem is a ruby wrapper for ngrok v2.x or v3.x.

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

**Pre-requisites:** You must have `ngrok` v2+ or v3+ installed available in your `PATH`.

**Upgrade Note:** Do not forget to run `ngrok config upgrade` after upgrading `ngrok` from v2.x to v3.x 

Add this line to your application's Gemfile:

```ruby
gem 'ngrok-wrapper'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ngrok-wrapper

## Usage

```ruby
require 'ngrok/wrapper'

# spawn ngrok (default port 3001)
Ngrok::Wrapper.start

# ngrok local_port
Ngrok::Wrapper.port
# => 3001

# ngrok external url
Ngrok::Wrapper.ngrok_url
# => "http://aaa0e65.ngrok.io"

Ngrok::Wrapper.ngrok_url_https
# => "https://aaa0e65.ngrok.io"

Ngrok::Wrapper.running?
# => true

Ngrok::Wrapper.stopped?
# => false

# ngrok process id
Ngrok::Wrapper.pid
# => 27384

# ngrok log file descriptor
Ngrok::Wrapper.log
# => #<File:/tmp/ngrok20141022-27376-cmmiq4>

# kill ngrok
Ngrok::Wrapper.stop
# => :stopped

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
if NGROK_ENABLED
  config.force_ssl = true
  config.hosts << URI.parse(NGROK_URL).host # for Rails >= 6.0.0
end  

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

## Gem Maintenance

### Preparing a release

Merge all the pull requests that should make it into the new release into the `main` branch, then checkout and pull the
branch and run the `github_changelog_generator`, specifying the new version as a `--future-release` cli parameter:

```
git checkout main
git pull

github_changelog_generator -u texpert -p ngrok-wrapper --future-release v0.1.0
```
Adjust the new gem version number in the `lib/ngrok/wrapper/version.rb` file.

Then add the changes to `git`, commit and push the `Preparing the new release` commit directly into the `main` branch:

```
git add .
git commit -m 'Preparing the new v0.1.0 release'
git push
```

### RubyGems credentials

Ensure you have the RubyGems credentials located in the `~/.gem/credentials` file.

### Adding a gem owner

```
gem owner ngrok-wrapper -a branzeanu.aurel@gmail.com
```

### Building a new gem version

Check if the new gem version number in the `lib/ngrok/wrapper/version.rb` file has been specified. 
It is used when building the gem by the following command:

```
gem build ngrok-wrapper.gemspec
```

Assuming the version was set to `0.1.0`,
a `ngrok-wrapper-0.1.0.gem` binary file will be generated at the root of the app (repo).

- The binary file shouldn't be added into the `git` tree, it will be pushed into the RubyGems and to the GitHub releases

### Pushing a new gem release to RubyGems

```
gem push ngrok-wrapper-0.1.0.gem # don't forget to specify the correct version number
```

### Crafting the new release on GitHub

On the [Releases page](https://github.com/texpert/ngrok-wrapper/releases) push the `Draft a new release` button.

The new release editing page opens, on which the following actions could be taken:

- Choose the repo branch (default is `main`)
- Insert a tag version (usually, the tag should correspond to the gem's new version, v0.1.0, for example)
  - the tag will be created by GitHub on the last commit into the chosen branch
- Fill the release Title and Description
- Attach the binary file with the generated gem version
- If the release is not yet ready for production, mark the `This is a pre-release` checkbox
- Press either the `Publish release`, or the `Save draft button` if you want to publish it later
  - After publishing the release, the the binary gem file will be available on GitHub and could be removed locally


## Contributing

1. Fork it ( https://github.com/texpert/ngrok-wrapper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
