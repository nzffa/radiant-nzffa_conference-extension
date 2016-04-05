class ConferenceSubscription < ActiveRecord::Base
  belongs_to :reader
  serialize :group_ids, Array
  serialize :partner_group_ids, Array
  
  accepts_nested_attributes_for :reader
  
  def has_group? id
    group_ids && group_ids.map(&:to_i).include?(id)
  end
  
  def partner_has_group? id
    couple? && partner_group_ids && partner_group_ids.map(&:to_i).include?(id)
  end
  
  def couple?
    single_or_couple == 'couple'
  end
  
  def paid?
    !paid_at.nil?
  end
  
  def paid_online?
    paid? && payment_method == 'online'
  end
  
  def update_group_ids_strings_to_integers
    if group_ids
      update_attribute :group_ids, group_ids.map{|sid| sid.to_i }
    end
  end
end
