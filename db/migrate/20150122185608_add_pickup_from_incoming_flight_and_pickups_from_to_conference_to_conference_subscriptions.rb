class AddPickupFromIncomingFlightAndPickupsFromToConferenceToConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :conference_subscriptions, :pickup_from_incoming_flight, :string
    add_column :conference_subscriptions, :pickups_from_to_conference, :string
  end

  def self.down
    remove_column :conference_subscriptions, :pickups_from_to_conference
    remove_column :conference_subscriptions, :pickup_from_incoming_flight
  end
end
