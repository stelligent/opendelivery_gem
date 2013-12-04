require 'simplecov'

SimpleCov.start do
  add_filter 'vendor'
end

require 'aws-sdk'
require File.expand_path('../../lib/opendelivery/domain.rb', __FILE__)
require File.expand_path('../../lib/opendelivery/stack.rb', __FILE__)

# choose your own adventure!
# load File.expand_path("~/.aws/aws.config")
 load File.expand_path("/opt/aws/aws.config")
#load File.expand_path("c:\\aws\\aws.config")
