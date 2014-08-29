class CreateConferenceSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :conference_subscriptions do |t|
      t.integer :reader_id
      t.text :options
      t.string :single_or_couple

      t.timestamps
    end
  end

  def self.down
    drop_table :conference_subscriptions
  end
end
