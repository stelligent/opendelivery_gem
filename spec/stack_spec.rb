require 'spec_helper'

describe OpenDelivery::Stack do
  context "Specifying region" do
    before(:each) do
      @stack = OpenDelivery::Stack.new("us-west-1")
    end
  end
end
