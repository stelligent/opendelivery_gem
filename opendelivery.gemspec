require 'rake'

$:.unshift File.expand_path('../lib', __FILE__)
require 'opendelivery/version'

Gem::Specification.new do |s|
  s.name          = 'opendelivery'
  s.license       = 'MIT'
  s.version       = Opendelivery::VERSION
  s.author        = [ "Brian Jakovich", "Jonny Sywulak", "Stelligent" ]
  s.email         = 'brian.jakovich@stelligent.com'
  s.homepage      = 'http://stelligent.com'
  s.platform      = Gem::Platform::RUBY
  s.summary       = "Open Delivery tools and utilities"
  s.description   = "A collection of tools that are used in the Open Delivery platform."
  s.files         = FileList[ "lib/*.rb","lib/opendelivery/*.rb" ]

  s.require_paths << 'lib'
  s.required_ruby_version = '>= 1.9.3'
  s.add_development_dependency('rdoc', '~> 4.1')
  s.add_development_dependency('rspec', '2.14.1')
  s.add_development_dependency('simplecov', '0.7.1')
  s.add_development_dependency('cucumber', '1.3.6')
  s.add_development_dependency('net-ssh', '2.9.0')
  s.add_runtime_dependency('encrypto_signo', '1.0.0')
  s.add_runtime_dependency('aws-sdk', '~> 1.0')
  s.add_runtime_dependency('aws-sdk-core', '~> 2.0')
  s.add_dependency('json', '~> 1.8')
end
