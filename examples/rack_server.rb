# Add the following code to the end of a configuration file of your preferred web-server,
# e.g. config/puma.rb, config/unicorn.rb, or config/thin.rb

# frozen_string_literal: true

# Use ~/.ngrok2/ngrok.yml as a config file.
# Don't forget to add it to `.gitignore' in the former case.
# Set NGROK_INSPECT=false to disable the inspector web-server.

require 'ngrok/wrapper'

options = { addr: 'https://localhost:3000', persistence: true }
options[:config] = ENV.fetch('NGROK_CONFIG', "#{ENV['HOME']}/.ngrok2/ngrok.yml")
options[:inspect] = ENV['NGROK_INSPECT'] if ENV['NGROK_INSPECT']

puts "[NGROK] tunneling at #{Ngrok::Wrapper.start(options)}"
puts '[NGROK] inspector web interface listening at http://127.0.0.1:4040' if ENV['NGROK_INSPECT'] == 'true'

NGROK_URL = Ngrok::Wrapper.ngrok_url_https
