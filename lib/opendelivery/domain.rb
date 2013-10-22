require 'aws-sdk'

module OpenDelivery
  class Domain

    def initialize(region=nil)
      if region.nil?
        @sdb = AWS::SimpleDB.new
      else
        @sdb = AWS::SimpleDB.new(:region => region)
      end
    end

    def create(domain)
      AWS::SimpleDB.consistent_reads do
        @sdb.domains.create(domain)
      end
    end

    def destroy(domain)
      AWS::SimpleDB.consistent_reads do
        @sdb.domains[domain].delete
      end
    end

    def destroy_item(domain, item_name)
      AWS::SimpleDB.consistent_reads do
        @sdb.domains[domain].items[item_name].delete
      end
    end

    def load_stack_properties(domain, stack)
      stack.resources.each do |resource|
        set_property(domain, stack.name, resource.resource_type, resource.physical_resource_id)
      end
    end

    def get_property(domain, item_name, key, index=0)
      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[domain].items[item_name]
        property_value = item.attributes[key].values[index].chomp
      end
    end

    def set_property(domain, item_name, key, value)
      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[domain].items[item_name]
        item.attributes.set(key => [value])
      end
    end
  end
end
