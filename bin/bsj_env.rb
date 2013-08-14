require 'aws-sdk'

@cfn = AWS::CloudFormation.new(
  :access_key_id => 'AKIAI7C7UKP3HCQ3IBFQ',
  :secret_access_key => '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',
  :region => 'us-west-1'
)

template = File.expand_path("../../../../infrastructure/cloudformation/jenkins.windows.template", __FILE__)


timestamp = Time.now.strftime("%M%S%L")
paramters = {
  "DesiredSize"        => "1",
  "ServerName"         => "A#{timestamp}",
  "InstanceType"       => "m1.large",
  "KeyPairName"        => "bsj-ctpdev",
  "VPCSubnet"          => "subnet-a35432ca",
  "VPCSecurityGroupId" => "sg-26cad34a",
  "GitUsername"        => "stelligent-service-user",
  "GitPassword"        => "advent1298",
  "Domain"             => "ctp.dev.com",
  "DomainUser"         => "ctp\\svcJoiner",
  "DomainPass"         => "Sequoia2012",
  "S3Bucket"           => "AdventResources",
  "SDBFile"            => "adventcloud.json",
  "AvailabilityZone"   => "us-west-1a",
  "AdminUser"          => "svcdevatlas",
  "AdminPassword"      => "Sequoia2012"
  }

@cfn.stacks.create("A#{timestamp}", File.open(template, "r").read, :parameters => paramters,
  :capabilities => ["CAPABILITY_IAM"])
