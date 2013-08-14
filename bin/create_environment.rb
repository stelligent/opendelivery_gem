require_relative '../config/initialize'

opts = Trollop::options do
  opt :sdbdomain, "Name of SimpleDB Domain", :short =>  "d", :type => String
  opt :stackname, "Name of CloudFormation Stack", :short =>  "s", :type => String
  opt :ec2keypair, "EC2 Keypair Name", :short => "k", :type => String
  opt :instancetype, "EC2 Instance Type", :short => "i", :type => String
  opt :vpcsubnet, "VPC Subnet to use", :short => "v", :type => String
  opt :templatename, "CloudFormation template name", :short => "n", :type => String
  opt :availabilityzone, "AZ for template to run in", :short => 'a', :type => String
end

domain = Domain.new
stack = Stack.new

template = File.expand_path("../../../../infrastructure/cloudformation/#{opts[:templatename]}", __FILE__)

params = {
  "DesiredSize"        => "1",
  "ServerName"         => opts[:stackname],
  "InstanceType"       => opts[:instancetype],
  "KeyPairName"        => opts[:ec2keypair],
  "VPCSubnet"          => domain.get_property(opts[:sdbdomain], "vpc", opts[:vpcsubnet]).to_s,
  "VPCSecurityGroupId" => domain.get_property(opts[:sdbdomain], "vpc", "security_group").to_s,
  "VPCID"              => domain.get_property(opts[:sdbdomain], "vpc", "id").to_s,
  "Domain"             => domain.get_property(opts[:sdbdomain], "active_directory", "domain").to_s,
  "DomainUser"         => domain.get_property(opts[:sdbdomain], "joiner", "username").to_s,
  "DomainPass"         => domain.get_property(opts[:sdbdomain], "joiner", "password").to_s,
  "S3Bucket"           => domain.get_property(opts[:sdbdomain], "s3_bucket", "name").to_s,
  "AvailabilityZone"   => "us-west-1a",
  "SimpleDBDomain"     => opts[:sdbdomain],
}

stack.create(template, opts[:stackname], params, opts[:stackname].include?('DB'))
