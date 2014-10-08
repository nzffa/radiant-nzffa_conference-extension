class AddNotesToConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :notes, :text
  end

  def self.down
    remove_column :conference_subscriptions, :notes
  end
end
