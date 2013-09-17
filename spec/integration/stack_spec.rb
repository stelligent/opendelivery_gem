require File.expand_path('../../spec_helper', __FILE__)

describe OpenDelivery::Stack do
  context "Specifying region" do
    before(:each) do
      @stack = OpenDelivery::Stack.new("us-west-1")
    end
  end
end
