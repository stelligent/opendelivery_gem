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

module OpsWorks

  def create_and_launch_stack(stack_description)
    stack_id = create_stack(stack_description)
    launch_stack(stack_id)
    deploy_apps(stack_id)
    stack_id
  end

  def create_and_launch_stack_in_order(stack_description, layers_by_order)
    stack_id = create_stack(stack_description)
    launch_stack_in_order(stack_id, layers_by_order)
    deploy_apps(stack_id)
    stack_id
  end

  def create_stack(stack_description)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new

    response = opsworks_client.create_stack(stack_description.stack_description)
    stack_id = response[:stack_id]

    wait_on_opsworks_sg_creation(stack_description.stack_description[:vpc_id]) if stack_description.stack_description[:vpc_id]

    layer_descriptions = stack_description.layer_descriptions
    layer_descriptions.each do |layer_description|
      layer_description[:layer][:stack_id] = stack_id

      response = opsworks_client.create_layer(layer_description[:layer])
      layer_id = response[:layer_id]
      layer_description[:layer][:layer_id] = layer_id

      layer_description[:instances].each do |instance_description|
        instance_description[:stack_id] = stack_id
        instance_description[:layer_ids] = [layer_id]

        save_off = instance_description[:extra_layers]
        instance_description.delete :extra_layers
        response = opsworks_client.create_instance(instance_description)
        instance_description[:instance_id] = response[:instance_id]
        instance_description[:extra_layers] = save_off
      end
    end

    layer_descriptions.each do |layer_description|
      layer_description[:instances].each do |instance_description|
        if instance_description[:extra_layers]
          instance_description[:extra_layers].each do |extra_layer_name|
            found_extra_layer = layer_descriptions.find { |desc| desc[:name] == extra_layer_name }

            raise "missing extra layer: #{extra_layer_name}" unless found_extra_layer
            instance_description[:layer_ids] << found_extra_layer[:layer_id]
            response = opsworks_client.update_instance(:instance_id => instance_description[:instance_id],
                                                       :layer_ids => instance_description[:layer_ids])
          end
        end
      end
    end

    stack_description.app_descriptions.each do |app_description|
      app_description[:stack_id] = stack_id
      response = opsworks_client.create_app(app_description)
    end

    stack_id
  end

  def launch_stack(stack_id)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new

    opsworks_client.start_stack(:stack_id => stack_id)

    wait_on_setup(stack_id)

    wait_on_all_configures(stack_id)
  end


  def launch_stack_in_order(stack_id, layers_by_order)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new

    layers_by_order.each do |layer_names|
      layer_names.each do |layer_name|

        response = opsworks_client.describe_layers( :stack_id => stack_id)
        layer = response[:layers].find { |layer| layer[:shortname] == layer_name }
        raise "layer #{layer_name} not found in stack: #{stack_id}" if layer.nil?

        response = opsworks_client.describe_instances( :layer_id => layer[:layer_id])
        response[:instances].each do |instance|
          opsworks_client.start_instance( :instance_id => instance[:instance_id])
        end
      end

      layer_names.each do |layer_name|
        response = opsworks_client.describe_layers( :stack_id => stack_id)
        layer = response[:layers].find { |layer| layer[:shortname] == layer_name }
        raise "layer #{layer_name} not found in stack: #{stack_id}" if layer.nil?

        wait_on_layer_setup(layer[:layer_id])
        wait_on_layer_configures(layer[:layer_id])
      end
    end
  end

  def deploy_apps(stack_id)
    deployment_ids = []
    opsworks_client = AWS::OpsWorks::Client::V20130218.new
    response = opsworks_client.describe_apps(:stack_id => stack_id)
    response[:apps].each do |app|

      puts "DEPLOYING THE APP: #{app}"
      response = opsworks_client.create_deployment(:stack_id => stack_id,
                                                   :app_id => app[:app_id],
                                                   :command => {
                                                     :name => 'deploy',
                                                     :args => deployment_args_factory(app)
                                                   })
      deployment_ids << response[:deployment_id]
    end

    max_attempts = 250
    num_attempts = 0

    deployments_complete = false
    until deployments_complete
      response = opsworks_client.describe_deployments(:deployment_ids => deployment_ids)
      deployments_complete = response[:deployments].inject(true) do |status, deployment|
        puts "Deployment status: #{deployment[:status]}"

        if deployment[:status] == 'failed'
          raise 'deployment failed'
        end

        status and (deployment[:status] == 'successful')
      end
      num_attempts += 1
      if num_attempts >= max_attempts
        raise 'stuck waiting on configure command max attempts'
      end
      sleep 10
    end
    deployment_ids
  end

  def discover_private_ips(stack_id, layer_name)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new
    response = opsworks_client.describe_layers( :stack_id => stack_id)
    layer = response[:layers].find { |layer| layer[:name] == layer_name }
    raise "layer #{layer_name} not found in stack: #{stack_id}" if layer.nil?

    response = opsworks_client.describe_instances( :layer_id => layer[:layer_id] )
    response[:instances].collect { |instance| instance[:private_ip] }
  end

  def discover_public_ips(stack_id, layer_name)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new
    response = opsworks_client.describe_layers( :stack_id => stack_id)
    layer = response[:layers].find { |layer| layer[:name] == layer_name }
    raise "layer #{layer_name} not found in stack: #{stack_id}" if layer.nil?

    response = opsworks_client.describe_instances( :layer_id => layer[:layer_id] )
    response[:instances].collect { |instance| instance[:public_ip] }
  end

  private

  def wait_on_opsworks_sg_creation(vpc_id)
    opsworks_security_group_names.each do |sg_name|
      while AWS.ec2.security_groups.filter('vpc-id', vpc_id).filter('group-name', sg_name).count == 0
        puts "Waiting on #{sg_name}, #{a = a ? a+1 : 1}"
        sleep 1
      end
    end
  end

  def opsworks_security_group_names
    %w{AWS-OpsWorks-Default-Server AWS-OpsWorks-Blank-Server AWS-OpsWorks-Custom-Server AWS-OpsWorks-Rails-App-Server}
  end

  def deployment_args_factory(app)
    if app[:type] == 'rails'
      {
        'migrate' => %w{true}
      }
    else
      {}
    end
  end

  def complete(status)
    failure(status) or success(status)
  end

  def failure(status)
    %w{setup_failed start_failed terminated connection_lost}.include? status
  end

  def success(status)
    %w{online}.include? status
  end

  def wait_on_setup(stack_id)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new

    setup_complete = false
    until setup_complete
      response = opsworks_client.describe_instances(:stack_id => stack_id)
      setup_complete = response[:instances].inject(true) do |status, instance|
        if failure(instance[:status])
          raise 'setup failed'
        end

        instance_status(instance)

        status and complete(instance[:status])
      end
      sleep 10
    end
  end

  def wait_on_layer_setup(layer_id)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new

    setup_complete = false
    until setup_complete
      response = opsworks_client.describe_instances(:layer_id => layer_id)
      setup_complete = response[:instances].inject(true) do |status, instance|
        if failure(instance[:status])
          raise 'setup failed'
        end

        instance_status(instance)

        status and complete(instance[:status])
      end
      sleep 10
    end
  end

  def instance_status(instance)
    puts "Instance: #{instance[:instance_id]} has status #{instance[:status]}"
  end

  def configure_status(configure_command)
    puts "Configure command: #{configure_command}"
  end

  def wait_on_all_configures(stack_id)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new
    response = opsworks_client.describe_instances(:stack_id => stack_id)
    response[:instances].each do |instance|
      wait_on_configure(instance[:instance_id])
    end
  end

  def wait_on_layer_configures(layer_id)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new
    response = opsworks_client.describe_instances(:layer_id => layer_id)
    response[:instances].each do |instance|
      wait_on_configure(instance[:instance_id])
    end
  end

  def wait_on_configure(instance_id)
    opsworks_client = AWS::OpsWorks::Client::V20130218.new

    max_attempts = 250
    num_attempts = 0

    while true
      response = opsworks_client.describe_commands(:instance_id => instance_id)
      configure_command = response[:commands].find { |command| command[:type] == 'configure' }

      configure_status(configure_command)

      unless configure_command.nil?
        #i guess just bail if superseded, waiting on configure events is somewhat dubious after seeing more complex stacks in action anyway!
        if %w{successful superseded}.include? configure_command[:status]
          return
        elsif configure_command[:status] == 'failed'
          raise 'configure failed'
        end
      end
      num_attempts += 1
      if num_attempts >= max_attempts
        raise 'stuck waiting on configure command max attempts'
      end
      sleep 10
    end
  end

end