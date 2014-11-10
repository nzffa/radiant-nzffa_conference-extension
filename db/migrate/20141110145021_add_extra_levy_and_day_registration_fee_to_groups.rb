class AddExtraLevyAndDayRegistrationFeeToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :day_registration_fee, :integer
    add_column :groups, :extra_levy, :integer
  end

  def self.down
    remove_column :groups, :day_registration_fee
    remove_column :groups, :extra_levy
  end
end
