class AddMemberNameToConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :member_name, :string
  end

  def self.down
    remove_column :conference_subscriptions, :member_name
  end
end
