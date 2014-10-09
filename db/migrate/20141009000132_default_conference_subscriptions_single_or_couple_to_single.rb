class DefaultConferenceSubscriptionsSingleOrCoupleToSingle < ActiveRecord::Migration
  def self.up
    change_column_default :conference_subscriptions, :single_or_couple, "single"
  end

  def self.down
    change_column_default :conference_subscriptions, :single_or_couple, ""
  end
end