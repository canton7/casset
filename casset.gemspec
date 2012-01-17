$LOAD_PATH.unshift(File.dirname(File.expand_path(__FILE__)))
require 'lib/casset/version'

Gem::Specification.new do |s|
  s.name = 'casset'
  s.version = Casset::VERSION
  s.summary = 'Casset: Asset management for Sinatra'
  s.description = 'Useful asset management for Sinatra, with parsing and minification'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Antony Male']
  s.email = 'antony dot mail at gmail'
  s.required_ruby_version = '>= 1.9.2'

  s.files = Dir['lib/**/*']
end
