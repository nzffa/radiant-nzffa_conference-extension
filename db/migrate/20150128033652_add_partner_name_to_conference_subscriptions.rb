class AddPartnerNameToConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :partner_name, :string
  end

  def self.down
    remove_column :conference_subscriptions, :partner_name
  end
end
