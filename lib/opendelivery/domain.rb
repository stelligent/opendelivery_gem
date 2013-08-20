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
      @sdb.domains[domain].delete
    end

    def destroy_item(domain, item_name)
      @sdb.domains[domain].items[item_name].delete
    end

    def get_property(domain, item_name, key)
      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[domain].items[item_name]
        item.attributes.each_value do |name, value|
          if name == key
            @property_value = value.chomp
          end
        end
      end

      return @property_value
    end

    def set_property(domain, item_name, property, value)
      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[domain].items[item_name]
        item.attributes.set(property => [value])
      end
    end
  end
end
