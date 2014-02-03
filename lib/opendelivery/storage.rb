#Copyright (c) 2014 Stelligent Systems LLC
#
#MIT LICENSE
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

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
