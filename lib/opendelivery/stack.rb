require 'aws-sdk'

module OpenDelivery
  class Stack

    def initialize(region=nil, silent=false, sleep_time=30)
      if region.nil?
        @cfn = AWS::CloudFormation.new
      else
        @cfn = AWS::CloudFormation.new(:region => region)
      end

      @sleep_time = sleep_time
      @silent = silent
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

    attr_accessor :sleep_time, :silent, :cfm

    def watch stack_name
      success = false
      begin
        stack = @cfn.stacks[stack_name]
        success = watch_loop stack
      rescue AWS::CloudFormation::Errors::ValidationError => msg
        print_status "Exception raised: #{msg}"
        success = false
      end
      return success
    end


    def create(template, stack_name, parameters = {}, wait=false)
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

    def print_status status
      timestamp = Time.now.strftime("%Y.%m.%d %H:%M:%S:%L")
      if (!@silent)
        puts "#{timestamp}: #{status}"
      end
    end

    def watch_loop stack
      keep_watching = true
      success = false
      abort_count = 10
      while(keep_watching) do
        begin
          stack_status = stack.status
          if (SUCCESS_STATUSES.include? stack_status)
            print_status "Success: #{stack_status}"
            success = true
            keep_watching = false
          elsif (PROGRESS_STATUSES.include? stack_status)
            print_status "In Progress: #{stack_status}"
            success = false
            keep_watching = true
          elsif (FAILURE_STATUSES.include? stack_status)
            print_status "Failed: #{stack_status}"
            success = false
            keep_watching = false
          else
            print_status "didn't find #{stack_status} in the list of expected statuses"
            success = false
            abort_count = abort_count - 1
            # if we get too many unknown statuses, assume something has gone horribly wrong and quit.
            keep_watching = (abort_count > 0)
          end
        rescue AWS::CloudFormation::Errors::Throttling
          print_status "Rate limit exceeded, retrying..."
          sleep (@sleep_time * 0.1)
        end
        sleep(@sleep_time)
      end
      return success
    end
  end
end
