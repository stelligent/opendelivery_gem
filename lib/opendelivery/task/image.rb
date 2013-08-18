require 'aws-sdk'

module OpenDelivery
  class Image

    def initialize cred
      @ec2 = AWS::EC2.new(cred)
      @auto_scale = AWS::AutoScaling.new(cred)
      @domain = OpenDelivery::Domain.new(cred)
    end

    def create(domain, stack_name, type, key)
      prepped_instance = prep_instance(domain stack_name)
      image = @ec2.images.create(instance_id: prepped_instance, name: stack_name)
      wait_for_image(image)
      @domain.set_property(domain, key, type, image.id)
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

    def prep_instance(domain stack_name)
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
