require_relative '../config/initialize'

opts = Trollop::options do
  opt :stackname, "Name of CloudFormation Stack (e.g., A54321-2-WEB)", :short =>  "s", :type => String
  opt :sdbdomain, "Name of sdb domain", :short => "q", :type => String
  opt :type, "Type of AMI to create (e.g., inf_web)", :short => "t", :type => String
end

image = OpenDelivery::Image.new

image.create(opts[:sdbdomain], opts[:stackname], opts[:type], "ami")
