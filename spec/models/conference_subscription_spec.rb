require File.dirname(__FILE__) + '/../spec_helper'

describe ConferenceSubscription do
  before(:each) do
    @conference_subscription = ConferenceSubscription.new
  end

  it "should be valid" do
    @conference_subscription.should be_valid
  end
end
