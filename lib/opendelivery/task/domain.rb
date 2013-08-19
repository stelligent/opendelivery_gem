require 'aws-sdk'

module OpenDelivery
  class Domain

    def initialize cred
      @sdb = AWS::SimpleDB.new(cred)
    end

    def create(domain_name)
      AWS::SimpleDB.consistent_reads do
        @sdb.domains.create(domain_name)
      end
    end

    def destroy(domain_name)
      @sdb.domains[domain_name].delete
    end

    def destroy_item(domain_name, item_name)
      @sdb.domains[domain_name].items[item_name].delete
    end

    def get_property(sdb_domain, item_name, key)
      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[sdb_domain].items[item_name]

        item.attributes.each_value do |name, value|
          if name == key
            @property_value = value.chomp
          end
        end
      end

      return @property_value
    end

    def set_property(sdb_domain, item_name, property, value)
      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[sdb_domain].items[item_name]

        item.attributes.set(property => [value])
      end
    end
  end
end