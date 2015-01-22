class AddDoNotPublishContactDetailsAndFirstConferenceToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :do_not_publish_contact_details, :boolean, :default => false
    add_column :conference_subscriptions, :first_conference, :boolean, :default => false
  end

  def self.down
    remove_column :conference_subscriptions, :first_conference
    remove_column :conference_subscriptions, :do_not_publish_contact_details
  end
end
