require_relative '../config/initialize'

opts = Trollop::options do
  opt :filename, "Name of file", :short => "n", :type => String
  opt :key, "Designated place to store file", :short => "k", :type => String
  opt :buildnumber, "Build identifier", :short => "i", :type => String
  opt :sdbdomain, "Name of sdb domain", :short => "q", :type => String
end

storage = OpenDelivery::Storage.new
artifact = OpenDelivery::Artifact.new
domain = OpenDelivery::Domain.new
s3 = AWS::S3.new

bucket = domain.get_property(opts[:sdbdomain], "s3_bucket", "name")

stamped_key = artifact.add_timestamp(opts[:buildnumber], opts[:key])

storage.upload(opts[:filename], bucket, stamped_key)

s3.buckets[bucket].objects[stamped_key].copy_to("#{opts[:key]}-latest")
