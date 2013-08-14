require_relative '../config/initialize'

opts = Trollop::options do
  opt :stackname, "Name of CloudFormation Stack", :short =>  "s", :type => String
  opt :sdbdomain, "Name of SimpleDB Domain", :short =>  "d", :type => String
end

domain = Domain.new
stack = Stack.new

domain.destroy_item(opts[:sdbdomain], opts[:stackname])
stack.destroy(opts[:stackname])
