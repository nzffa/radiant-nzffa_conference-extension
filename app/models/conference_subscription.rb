class ConferenceSubscription < ActiveRecord::Base
  belongs_to :reader
  serialize :group_ids, Array
  
  def has_group? id
    group_ids && group_ids.include?(id.to_s)
  end
end
