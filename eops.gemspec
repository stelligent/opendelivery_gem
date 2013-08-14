require File.join([ File.dirname(__FILE__), 'lib', 'eops', 'version.rb' ])
spec = Gem::Specification.new do |s|
  s.name = 'eops'
  s.version = Eops::VERSION
  s.author = ["Brian Jakovich", "Jonny Sywulak"]
  s.email = 'brian.jakovich@stelligent.com'
  s.homepage = 'http://stelligent.com'
  s.platform = Gem::Platform::RUBY
  s.summary = "Elastic Operations tools and utilities"
  s.description = "A collection of tools that are used in the Elastic Operations Continuous Delivery Pipeline."
  s.files = %w(
lib/eops/artifact.rb
lib/eops/database.rb
lib/eops/domain.rb
lib/eops/image.rb
lib/eops/instance.rb
lib/eops/key_pair.rb
lib/eops/stack.rb
lib/eops/storage.rb
  )
  s.require_paths << 'lib'
  s.required_ruby_version = '>= 1.9.3'
  s.add_development_dependency('aws-sdk', '1.15.0')
  s.add_runtime_dependency('aws-sdk', '1.15.0')
end
