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
  class MachineImage

    def initialize(region=nil)
      if region.nil?
        @ec2 = AWS::EC2.new
        @sdb = AWS::SimpleDB.new
        @auto_scale = AWS::AutoScaling.new
        @domain = OpenDelivery::Domain.new
      else
        @ec2 = AWS::EC2.new(:region => region)
        @sdb = AWS::SimpleDB.new(:region => region)
        @auto_scale = AWS::AutoScaling.new(:region => region)
        @domain = OpenDelivery::Domain.new(:region => region)
      end
    end

    def create(domain, stack_name)
      instance_id = prep_instance(domain, stack_name)
      image = @ec2.images.create(
        instance_id: instance_id,
        name: image_name)

      wait_for_image(image)
    end

    protected

    def wait_for_image(image)
      # Waiting for AWS to realize the image is ready to start
      sleep 10

      while image.state != :available
        sleep 10
        case image.state
        when :failed
          image.delete
          raise RuntimeError, 'Image Creation Failed'
        end
      end
    end

    def prep_instance(domain, stack_name)
      group_name = @domain.get_property(domain, stack_name, "AWS::AutoScaling::AutoScalingGroup")
      instance = @auto_scale.groups[group_name].auto_scaling_instances.first.id
      @ec2.instances[instance].stop

      while @ec2.instances[instance].status != :stopped
        sleep 10
      end
      return instance
    end
  end
end
