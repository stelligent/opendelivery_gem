require File.expand_path('../../spec_helper', __FILE__)

describe OpenDelivery::Stack do
  context "Specifying region" do
    before(:each) do
      @domain = "opendelivery-test-domain"
      @stack_under_test = "opendelivery-test-stack"
      @domain_under_test = OpenDelivery::Domain.new("us-west-1")
      @domain_under_test.create(@domain)
      @stack = OpenDelivery::Stack.new("us-west-1")
    end

    describe "create stack" do
      it "should be able to create a stack without tags" do
        @stack.create(@stack_under_test, "spec/stack.template")
      end
      it "should be able to create a stack with tags" do
        @stack.create(@stack_under_test, "spec/stack.template", [{}], false, nil, [{ key: "Name", value: "test"}])
      end
    end

    after(:each) do
      @stack.destroy(@stack_under_test, @domain)
      sleep 15
    end
  end
end
