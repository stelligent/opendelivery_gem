require 'opendelivery/version.rb'
require 'opendelivery/task.rb'

module OpenDelivery
  def self.perform aws_credentials, klass, method, *args
    response = {}

    response[:task] = begin
      response[:formatted] = Task.const_get(klass).new(aws_credentials).send(method, *args)
    rescue AWS::Errors::Base => e
      response[:formatted] = "AWS error: #{e}"
      false
    rescue
      response[:formatted] = "Unknown error"
      false
    end
    response
  end
end
