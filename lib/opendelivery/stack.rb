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
  class Stack

    def initialize(region=nil)
      if region.nil?
        @cfn = AWS::CloudFormation.new
        @autoscaling = AWS::AutoScaling.new
      else
        @autoscaling = AWS::AutoScaling.new(:region => region)
        @cfn = AWS::CloudFormation.new(:region => region)
      end
      @domain = OpenDelivery::Domain.new(region)
    end


    SUCCESS_STATUSES =  [ "CREATE_COMPLETE",
      "UPDATE_COMPLETE" ]

    FAILURE_STATUSES =  [ "CREATE_FAILED",
      "ROLLBACK_FAILED",
      "ROLLBACK_COMPLETE",
      "DELETE_FAILED",
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


    def create(stack_name, template, parameters = {}, wait=false, domain=nil, tags = {})
      @cfn.stacks.create(stack_name,
        File.open(template, "r").read,
        :parameters => parameters,
        :tags => tags,
        :capabilities => ["CAPABILITY_IAM"],
        :disable_rollback => true)
    end

    def destroy(stack_name, domain=nil, wait=false)
      stack = @cfn.stacks[stack_name]
      if stack.exists?
        resume_scaling_activities(stack_name)
        stack.delete
        while wait and stack.exists?
          sleep 20
        end
        @domain.destroy_item(domain, stack_name)
      else
        raise "Stack: #{stack_name} doesn't exist, therefore it cannot be destroyed"
      end
    end

    def list
      @cfn.stacks.each do |stack|
        puts "Stack Name: #{stack.name} | Status: #{stack.status}"
      end
    end

    def resume_scaling_activities(stack_name)
      stack = @cfn.stacks[stack_name]
      stack.resources.each do |resource|
        if resource.resource_type == "AWS::AutoScaling::AutoScalingGroup"
          begin
            @autoscaling.groups[resource.physical_resource_id].resume_all_processes
          rescue Exception => e
            puts "ASG operation failed with [#{e.message}]"
          end
        end
      end
    end

    protected

    def wait_for_stack(stack, wait)
      if wait
        while stack.status != "CREATE_COMPLETE"
          sleep 20

          if FAILURE_STATUSES.include? stack.status
            stack.delete
          end
        end
      end
    end

    def print_status(status, silent=false)
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
          sleep(sleep_time * 0.1)
        end
        if keep_watching
          sleep(sleep_time)
        end
      end
      return success
    end
  end
end
