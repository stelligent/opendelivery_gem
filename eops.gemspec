require 'rake'

Gem::Specification.new do |s|
  s.name        = 'eops'
  s.version     = '0.0.1'
  s.date        = '2013-08-13'
  s.summary     = "Elastic Operations tools and utilities"
  s.description = "A collection of tools that are used in the Elastic Operations Continuous Delivery Pipeline."
  s.authors     = ["Brian Jakovich", "Jonny Sywulak"]
  s.email       = 'brian.jakovich@stelligent.com'
  s.files       = FileList['lib/**/*.rb'].to_a
end