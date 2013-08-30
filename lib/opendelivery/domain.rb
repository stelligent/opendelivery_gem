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

    def get_property(domain, item_name, key)
      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[domain].items[item_name]
        property_value = item.attributes[key].values[0].chomp
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
