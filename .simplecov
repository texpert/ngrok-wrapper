# frozen_string_literal: true

SimpleCov.start do
  require 'simplecov_json_formatter'

  formatter SimpleCov::Formatter::JSONFormatter
  enable_coverage :branch
  primary_coverage :branch
  add_filter '/spec/'
end
