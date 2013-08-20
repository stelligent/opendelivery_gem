require 'aws-sdk'

module OpenDelivery
  class Stack

    def initialize(region=nil)
      if region.nil?
        @cfn = AWS::CloudFormation.new
      else
        @cfn = AWS::CloudFormation.new(:region => region)
      end
      @domain = OpenDelivery::Domain.new
    end

    def create(template, domain, stack_name, parameters = {}, wait=false)
      stack = @cfn.stacks.create(stack_name,
        File.open(template, "r").read,
        :parameters => parameters,
        :capabilities => ["CAPABILITY_IAM"],
        :disable_rollback => true)

      if wait
        wait_for_stack(stack)
      end

      stack.resources.each do |resource|
        @domain.set_property(domain, stack_name, resource.resource_type, resource.physical_resource_id)
      end
    end

    def destroy(domain, stack_name)
      stack = @cfn.stacks[stack_name]
      stack.delete
      while stack.exists?
        sleep 20
      end
      @domain.destroy_item(domain, stack_name)
    end

    def list
      @cfn.stacks.each do |stack|
        puts "Stack Name: #{stack.name} | Status: #{stack.status}"
      end
    end

    protected

    def wait_for_stack(stack)
      while stack.status != "CREATE_COMPLETE"
        sleep 20

        case stack.status
        when "ROLLBACK_IN_PROGESS" || "ROLLBACK_COMPLETE"
          stack.delete
        end
      end
    end
  end
end
