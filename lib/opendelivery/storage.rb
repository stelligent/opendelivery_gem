require 'aws-sdk'

module OpenDelivery
  class Storage

    def initialize(region=nil)
      if region.nil?
        @s3 = AWS::S3.new
      else
        @s3 = AWS::S3.new(:region => region)
      end
    end

    def copy(bucket, key, desired_key)
      @s3.buckets[bucket].objects[key].copy_to(desired_key)
    end

    def upload(bucket, file, key)
      @s3.buckets[bucket].objects[key].write(:file => file)
    end

    def download(bucket, key, output_directory)
      # Puke if the bucket doesn't exist
      raise "Bucket #{bucket} doesn't exist" unless @s3.buckets[bucket].exists?

      # Puke if the key doesn't exist. This can cause problems with some bucket policies, so we catch and re-throw
      begin
        raise "File with key #{key} doesn't exist in bucket #{bucket}" unless @s3.buckets[bucket].objects[key].exists?
      rescue Exception => e
        raise "Exception [#{e.message}] occurred downloading key #{key} from bucket #{bucket}"
      end

      obj = @s3.buckets[bucket].objects[key]

      base = Pathname.new("#{obj.key}").basename

      Dir.mkdir(output_directory) unless File.exists?(output_directory)

      File.open("#{output_directory}/#{base}", 'wb') do |file|
        obj.read do |chunk|
          file.write(chunk)
        end
      end
    end

    def add_timestamp(identifier, artifact)
      timestamp = Time.now.strftime("%Y.%m.%d.%H.%M.%S.%L")
      stamped_artifact = "#{artifact}-#{identifier}-#{timestamp}"
      return stamped_artifact
    end
  end
end
