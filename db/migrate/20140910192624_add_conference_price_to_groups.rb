class AddConferencePriceToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :conference_price, :integer, :allow_nil => true
  end

  def self.down
    remove_column :groups, :conference_price
  end
end
