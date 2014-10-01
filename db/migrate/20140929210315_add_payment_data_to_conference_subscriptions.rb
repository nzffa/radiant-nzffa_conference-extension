class AddPaymentDataToConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :payment_method, :string
    add_column :conference_subscriptions, :paid_amount, :integer, :default => 0
    add_column :conference_subscriptions, :paid_at, :datetime
    add_column :conference_subscriptions, :levy, :integer
  end

  def self.down
    remove_column :conference_subscriptions, :paid_amount
    remove_column :conference_subscriptions, :payment_method
    remove_column :conference_subscriptions, :paid_at
    remove_column :conference_subscriptions, :levy
  end
end