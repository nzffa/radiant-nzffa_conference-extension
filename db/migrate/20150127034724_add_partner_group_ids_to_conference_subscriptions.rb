class AddPartnerGroupIdsToConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :partner_group_ids, :text
    # For existing subscriptions, update group_ids array values from string to integer
    ConferenceSubscription.all.each do |cs|
      cs.update_group_ids_strings_to_integers
    end
  end

  def self.down
    remove_column :conference_subscriptions, :partner_group_ids
  end
end
