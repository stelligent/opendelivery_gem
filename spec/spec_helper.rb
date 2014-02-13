require 'simplecov'

SimpleCov.start do
  add_filter 'vendor'
end

require 'aws-sdk'
require File.expand_path('../../lib/opendelivery/domain.rb', __FILE__)
require File.expand_path('../../lib/opendelivery/stack.rb', __FILE__)


# choose your own adventure!
#config_file = "~/.aws/aws.config"
#config_file = "c:\\aws\\aws.config"
config_file = "/opt/aws/aws.config"
if File.exist?(config_file)
  load File.expand_path(config_file)
end
