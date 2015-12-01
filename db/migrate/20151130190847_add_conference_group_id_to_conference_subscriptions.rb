class AddConferenceGroupIdToConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :conference_group_id, :integer
  end

  def self.down
    remove_column :conference_subscriptions, :conference_group_id
  end
end
