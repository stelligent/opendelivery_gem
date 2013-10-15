require File.expand_path('../../spec_helper', __FILE__)

describe OpenDelivery::Domain do

  context "Specifying region" do
    before(:each) do
      @domain_name = "opendeliverytest_domain_1"
      @domain_under_test = OpenDelivery::Domain.new("us-west-1")
      @sdb = AWS::SimpleDB.new(:region => "us-west-1")
    end

    describe "create domain" do
      it "should be able to create a domain in another region" do
        @domain_under_test.create(@domain_name)
        @sdb.domains[@domain_name].exists?.should eql true
      end
    end

    describe "Delete domain" do
      it "should be able to create a domain in another region" do

        AWS::SimpleDB.consistent_reads do
          @sdb.domains.create(@domain_name)
        end

        @domain_under_test.destroy(@domain_name)
        @sdb.domains[@domain_name].exists?.should eql false
      end
    end

    after(:each) do
      puts "\n============= RUNNING THE AFTER BLOCK ================"
      AWS::SimpleDB.consistent_reads do
        @sdb.domains[@domain_name].delete!
      end
    end
  end

  context "Not specifying region" do

    before(:each) do
      @domain_name = "opendeliverytest_domain_2"
      @domain_under_test = OpenDelivery::Domain.new
      @sdb = AWS::SimpleDB.new
    end

    describe "create domain" do
      it "should be able to create a domain" do
        @domain_under_test.create(@domain_name)
      end
    end

     describe "Delete domain" do
      it "should be able to create a domain in another region" do

        AWS::SimpleDB.consistent_reads do
          @sdb.domains.create(@domain_name)
        end

        @domain_under_test.destroy(@domain_name)
        @sdb.domains[@domain_name].exists?.should eql false
      end
    end

    describe "destroy item" do

      before(:each) do
        @item_name = "item_name"
        @key = "test_key_1"
        @expected_value = "test_value_1"

        AWS::SimpleDB.consistent_reads do
          @sdb.domains.create(@domain_name)
        end

        @sdb.domains[@domain_name].items.create(@item_name, { @key => @expected_value } )
      end

      it "should destroy the item" do
        @domain_under_test.destroy_item(@domain_name, @item_name)
        AWS::SimpleDB.consistent_reads do
          @sdb.domains[@domain_name].items.size.should eql 0
        end
      end

    end

    describe "get property" do

      before(:each) do
        @item_name = "item_name"
        @key = "test_key_1"
        @expected_value = "test_value_1"
        @expected_value2 = "test_value_2"

        AWS::SimpleDB.consistent_reads do
          @sdb.domains.create(@domain_name)
        end

        @sdb.domains[@domain_name].items.create(@item_name, { @key => [@expected_value, @expected_value2] } )
      end

      it "should return the proper value for the specified key" do
        actual_value = @domain_under_test.get_property(@domain_name, @item_name, @key)
        actual_value.should eql @expected_value
      end


      it "should return the proper value for the specified key when giving an index" do
        actual_value = @domain_under_test.get_property(@domain_name, @item_name, @key, 1)
        actual_value.should eql @expected_value2
      end

    end

    describe "set property" do

      before(:each) do
        @item_name = "item_name"
        @key = "test_key_1"
        @expected_value = "test_value_1"

        AWS::SimpleDB.consistent_reads do
          @sdb.domains.create(@domain_name)
        end
      end

      it "should set the specified value for the specified key" do
        @domain_under_test.set_property(@domain_name, @item_name, @key, @expected_value)

        AWS::SimpleDB.consistent_reads do
          actual_value = @sdb.domains[@domain_name].items[@item_name].attributes[@key].values[0].chomp
          actual_value.should eql @expected_value
        end
      end

      it "should set the value for the key to only a single value" do
        @domain_under_test.set_property(@domain_name, @item_name, @key, @expected_value)
        AWS::SimpleDB.consistent_reads do
          actual_value = @sdb.domains[@domain_name].items[@item_name].attributes[@key].values[0].chomp
          actual_value.should eql @expected_value
        end

        @domain_under_test.set_property(@domain_name, @item_name, @key, @expected_value)
        AWS::SimpleDB.consistent_reads do
          actual_value = @sdb.domains[@domain_name].items[@item_name].attributes[@key].values[0].chomp
          actual_value.should eql @expected_value
          @sdb.domains[@domain_name].items[@item_name].attributes[@key].values.size.should eql 1
        end
      end
    end
    after(:each) do
      puts "\n============= RUNNING THE AFTER BLOCK ================"
      AWS::SimpleDB.consistent_reads do
        @sdb.domains[@domain_name].delete!
      end
    end
  end
end
