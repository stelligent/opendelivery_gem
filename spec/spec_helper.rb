require 'simplecov'

SimpleCov.start do
  add_filter 'vendor'
end

require 'aws-sdk'
require File.expand_path('../../lib/opendelivery/domain.rb', __FILE__)
load File.expand_path("/opt/aws/aws.config")
