class ConferenceSubscription < ActiveRecord::Base
  belongs_to :reader
  serialize :group_ids, Array
  
  accepts_nested_attributes_for :reader
  
  def has_group? id
    group_ids && group_ids.include?(id.to_s)
  end
  
  def paid?
    paid_amount == levy
  end
  
  def paid_online?
    paid? && payment_method == 'online'
  end
end
