require 'aws-sdk'

module OpenDelivery
  class Stack

    def initialize(region=nil)
      if region.nil?
        @cfn = AWS::CloudFormation.new
      else
        @cfn = AWS::CloudFormation.new(:region => region)
      end
      @domain = OpenDelivery::Domain.new region
    end


    SUCCESS_STATUSES =  [ "CREATE_COMPLETE",
      "UPDATE_COMPLETE" ]

    FAILURE_STATUSES =  [ "CREATED_FAILED",
      "ROLLBACK_FAILED",
      "ROLLBACK_COMPLETE",
      "DELETED_FAILED",
      "UPDATE_ROLLBACK_FAILED",
      "UPDATE_ROLLBACK_COMPLETE",
      "DELETE_COMPLETE" ]

    PROGRESS_STATUSES = [ "CREATE_IN_PROGRESS",
      "ROLLBACK_IN_PROGRESS",
      "DELETE_IN_PROGRESS",
      "UPDATE_IN_PROGRESS",
      "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS",
      "UPDATE_ROLLBACK_IN_PROGRESS",
      "UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS" ]

    def watch(stack_name, sleep_time, silent=false)
      success = false
      begin
        stack = @cfn.stacks[stack_name]
        success = watch_loop(stack, sleep_time, silent)
      rescue AWS::CloudFormation::Errors::ValidationError => msg
        print_status "Exception raised: #{msg}"
        success = false
      end
      return success
    end


    def create(stack_name, template, parameters = {}, wait=false, domain=nil)
      stack = @cfn.stacks.create(stack_name,
        File.open(template, "r").read,
        :parameters => parameters,
        :capabilities => ["CAPABILITY_IAM"],
        :disable_rollback => true)

      if wait
        wait_for_stack(stack)
      end

      if domain.nil
        stack.resources.each do |resource|
          @domain.set_property(domain, stack_name, resource.resource_type, resource.physical_resource_id)
        end
      end
    end

    def destroy(stack_name, domain=nil, wait=false)
      stack = @cfn.stacks[stack_name]
      unless stack.exists? raise "Stack: #{stack_name} doesn't exist, therefore it cannot be destroyed"
      stack.delete
      while wait and stack.exists?
        sleep 20
      end
      @domain.destroy_item(domain, stack_name)
    end

    def list
      @cfn.stacks.each do |stack|
        puts "Stack Name: #{stack.name} | Status: #{stack.status}"
      end
    end

    private

    def wait_for_stack(stack)
      while stack.status != "CREATE_COMPLETE"
        sleep 20

        if FAILURE_STATUSES.include? stack.status
          stack.delete
        end
      end
    end

    def print_status(status, silent)
      timestamp = Time.now.strftime("%Y.%m.%d %H:%M:%S:%L")
      unless silent
        puts "#{timestamp}: #{status}"
      end
    end

    def watch_loop(stack, sleep_time, silent)
      keep_watching = true
      success = false
      abort_count = 10
      while(keep_watching) do
        begin
          stack_status = stack.status
          if (SUCCESS_STATUSES.include? stack_status)
            status = "Success: #{stack_status}"
            print_status(status, silent)
            success = true
            keep_watching = false
          elsif (PROGRESS_STATUSES.include? stack_status)
            status = "In Progress: #{stack_status}"
            print_status(status, silent)
            success = false
            keep_watching = true
          elsif (FAILURE_STATUSES.include? stack_status)
            status = "Failed: #{stack_status}"
            print_status(status, silent)
            success = false
            keep_watching = false
          else
            status = "didn't find #{stack_status} in the list of expected statuses"
            print_status(status, silent)
            success = false
            abort_count = abort_count - 1
            # if we get too many unknown statuses, assume something has gone horribly wrong and quit.
            keep_watching = (abort_count > 0)
          end
        rescue AWS::CloudFormation::Errors::Throttling
          status = "Rate limit exceeded, retrying..."
          print_status(status, silent)
          sleep (sleep_time * 0.1)
        end
        sleep(sleep_time)
      end
      return success
    end
  end
end
