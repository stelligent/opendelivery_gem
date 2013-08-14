require_relative '../config/initialize'

opts = Trollop::options do
  opt :stackname, "Name of CloudFormation Stack", :short =>  "s", :type => String
  opt :sdbdomain, "Name of sdb domain", :short => "q", :type => String
  opt :imagename, "Name of image", :short =>  "i", :type => String
  opt :type, "Type of AMI to create", :short => "t", :type => String
end

image = Image.new
domain = Domain.new
stack = Stack.new

as_group_name = domain.get_property(opts[:sdbdomain], opts[:stackname], "AWS::AutoScaling::AutoScalingGroup"

image.create(as_group_name, opts[:imagename], opts[:sdbdomain], opts[:type], "ami")
