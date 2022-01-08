SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
  add_filter '/examples/'
  add_filter '/spec/'
end
