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
require 'encrypto_signo'

module OpenDelivery
  class Domain

    def initialize(region=nil, key_path=nil)
      @key_path = File.read(key_path) unless key_path.nil?

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
      AWS::SimpleDB.consistent_reads do
        stack.resources.each do |resource|
          set_property(domain, stack.name, resource.resource_type, resource.physical_resource_id)
        end
      end
    end

    def get_encrypted_property(domain, item_name, key, index=0, name=nil)
      value = get_property(domain, item_name, key, index, name)
      decrypted_value = EncryptoSigno.decrypt(@key_path, value.chomp)
    end

    # Look for AWS::Some:Type|MyItemName or just AWS::Some::Type.

    def get_property(domain, item_name, key, index=0, name=nil)
      property_value = nil
      attribute      = nil

      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[domain].items[item_name]
        if !item.nil?
          item.attributes.each do |att|
            col_name = nil

            att_array = att.name.split('|')
            col_title = att_array.first

            if att_array.length > 1
              col_name = att_array[1]
            end

            if col_title == key
              # Found a column with first portion that matches our search 'key'
              # Now, determine if we need to match the "|name" name criteria.

              if name.nil?
                # Not given a name to search for, just return the first one
                # we have found.
                attribute = att
                break
              else

                # Give a 'name' search criteria, so match it against this column
                if name == col_name
                  # 'name' criteria matches "|name" value, found a match
                  attribute = att
                  break
                else
                  # 'name' criteria did not match, keep searching
                end

              end
            end
          end
          if !attribute.nil?
            value = attribute.values[index]
            if !value.nil?
              property_value = value.chomp
            end
          end
        end
      end
      return property_value
    end

    def set_encrypted_property(domain, item_name, key, value, name=nil)
      encrypted_value = EncryptoSigno.encrypt(@key_path, value.chomp)
      set_property(domain, item_name, key, encrypted_value, name)
    end

    def set_property(domain, item_name, key, value, name=nil)
      if name then key = key + "|" + name end

      AWS::SimpleDB.consistent_reads do
        item = @sdb.domains[domain].items[item_name]
        item.attributes.set(key => [value])
      end
    end

    def load_domain(domain, json_file)
      json = File.read(json_file)
      obj = JSON.parse(json)

      obj.each do |item, attributes|
        attributes.each do |key,value|
          AWS::SimpleDB.consistent_reads do
            @sdb.domains[domain].items[item].attributes.set(key => [value])
          end
        end
      end
    end
  end
end
