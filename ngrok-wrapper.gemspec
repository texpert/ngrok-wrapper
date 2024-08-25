# frozen_string_literal: true

lib = "#{__dir__}/lib"
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative 'lib/ngrok/wrapper/version'

Gem::Specification.new do |spec|
  spec.name = 'ngrok-wrapper'
  spec.version = Ngrok::Wrapper::VERSION
  spec.authors = ['Anton Bogdanovich', 'Aureliu Brinzeanu']
  spec.email = %w[27bogdanovich@gmail.com branzeanu.aurel@gmail.com]

  spec.summary = 'Ngrok-wrapper gem is a ruby wrapper for ngrok2'
  spec.description = 'Ngrok-wrapper gem is a ruby wrapper for ngrok2'
  spec.homepage = 'https://github.com/texpert/ngrok-wrapper'
  spec.required_ruby_version = '>= 3.1.0'
  spec.license = 'MIT'

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/texpert/ngrok-wrapper'
  spec.metadata['changelog_uri'] = 'https://github.com/texpert/ngrok-wrapper/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ['lib']
end
