require_relative '../config/initialize'

opts = Trollop::options do
  opt :sdbdomain, "Name of SimpleDB Domain", :short =>  "d", :type => String
  opt :stackname, "Name of CloudFormation Stack", :short =>  "s", :type => String
end

cfn = AWS::CloudFormation.new
domain = Domain.new

cfn.stacks[opts[:stackname]].resources.each do |resource|
  domain.set_property(opts[:sdbdomain], opts[:stackname], resource.resource_type, resource.physical_resource_id)
end
