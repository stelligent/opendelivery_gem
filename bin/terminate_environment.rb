require_relative '../config/initialize'

opts = Trollop::options do
  opt :stackname, "Name of CloudFormation Stack", :short =>  "s", :type => String
  opt :sdbdomain, "Name of SimpleDB Domain", :short =>  "d", :type => String
end

stack = OpenDelivery::Stack.new

stack.destroy(opts[:sdbdomain], opts[:stackname])
