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

require 'aws-sdk-simpledb'
require 'encrypto_signo'

module OpenDelivery
  class Domain

    def initialize(region=nil, key_path=nil)
      @key_path = File.read(key_path) unless key_path.nil?

      if region.nil?
        @sdb = Aws::SimpleDB::Client.new
      else
        @sdb = Aws::SimpleDB::Client.new(:region => region)
      end
    end

    def create(domain)
      @sdb.create_domain(domain_name: domain)
    end

    def destroy(domain)
      @sdb.delete_domain(domain_name: domain)
    end

    def destroy_item(domain, item_name)
      @sdb.delete_attributes(domain_name: domain,
                             item_name: item_name)
    end

    def load_stack_properties(domain, stack)
      stack.resources.each do |resource|
        set_property(domain,
                     stack.name,
                     resource.resource_type,
                     resource.physical_resource_id)
      end
    end

    def get_encrypted_property(domain, item_name, key)
      value = get_property(domain, item_name, key)
      EncryptoSigno.decrypt(@key_path, value.chomp)
    end

    def get_property(domain, item_name, key)
      get_attributes_response = @sdb.get_attributes(domain_name: domain,
                                                    item_name: item_name,
                                                    attribute_names: [key],
                                                    consistent_read: true)

      if get_attributes_response.attributes.empty?
        nil
      else
        get_attributes_response.attributes.first.value.chomp
      end
    end

    def get_item_attributes_json(domain, item_name)
      get_attributes_response = @sdb.get_attributes(domain_name: domain,
                                                    item_name: item_name,
                                                    consistent_read: true)

      if get_attributes_response.attributes.empty?
        nil
      else
        JSON.generate(get_attributes_response.attributes.map { |attribute|
          { name: attribute.name, value: attribute.value }
        })
      end
    end

    def set_encrypted_property(domain, item_name, key, value)
      encrypted_value = EncryptoSigno.encrypt(@key_path, value.chomp)
      set_property(domain, item_name, key, encrypted_value)
    end

    def set_property(domain, item_name, key, value)
      @sdb.put_attributes(domain_name: domain,
                          item_name: item_name,
                          attributes: [
                            {
                              name: key,
                              value: value,
                              replace: true,
                            }
                          ])
    end

    def load_domain(domain, json_file)
      json = File.read(json_file)
      obj = JSON.parse(json)

      obj.each do |item, attributes|
        attributes.each do |key,value|
          set_property(domain, item, key, value)
        end
      end
    end
  end
end
