require File.dirname(__FILE__) + '/../spec_helper'

describe GwoTest do
  before(:each) do
    @gwo_test = GwoTest.new
  end

  it "should be valid" do
    @gwo_test.should be_valid
  end
end
