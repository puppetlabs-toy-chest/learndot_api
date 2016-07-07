require 'date'

Gem::Specification.new do |s|
  s.name         = 'learndot_api'
  s.version      = '0.2.0'
  s.date         = Date.today.to_s
  s.summary      = 'Learndot API'
  s.homepage     = "http://learn.puppet.com"
  s.description  = 'Methods to retrieve records from Learndot Enterprise API'
  s.authors      = ['Michael Marrero']
  s.email        = 'michael.marrero@puppet.com'
  s.license      = 'MIT'
  s.has_rdoc     = false
  s.require_path = 'lib'

  s.files        = %w( CHANGELOG README.md )
  s.files       += Dir.glob("lib/**/*")
  s.files       += Dir.glob("examples/**/*")

  s.add_dependency 'httparty', '~> 0.13.7'
end
