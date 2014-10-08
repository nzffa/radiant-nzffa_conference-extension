class AddGroupIdsToConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :group_ids, :text
  end

  def self.down
    remove_column :conference_subscriptions, :group_ids
  end
end
