require_relative '../config/initialize'

opts = Trollop::options do
  opt :filename, "Name of file", :short => "n", :type => String
  opt :key, "Designated place to store file", :short => "k", :type => String
  opt :buildnumber, "Build identifier", :short => "i", :type => String
  opt :sdbdomain, "Name of sdb domain", :short => "q", :type => String
end

storage = Storage.new
artifact = Artifact.new
domain = Domain.new

bucket = domain.get_property(opts[:sdbdomain], "s3_bucket", "name")

stamped_key = artifact.add_timestamp(opts[:buildnumber], opts[:key])

storage.upload(opts[:filename], bucket, stamped_key)

storage.copy(bucket, stamped_key, "#{opts[:key]}-latest")
