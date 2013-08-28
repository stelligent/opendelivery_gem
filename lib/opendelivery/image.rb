module OpenDelivery
  class Image

    def initialize(region=nil)
      if region.nil?
        @ec2 = AWS::EC2.new
        @sdb = AWS::SimpleDB.new
        @auto_scale = AWS::AutoScaling.new
      else
        @ec2 = AWS::EC2.new(:region => region)
        @sdb = AWS::SimpleDB.new(:region => region)
        @auto_scale = AWS::AutoScaling.new(:region => region)
      end
    end

    protected

    def wait_for_image(image)
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
