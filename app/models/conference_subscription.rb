class ConferenceSubscription < ActiveRecord::Base
  belongs_to :reader
  serialize :group_ids, Array
  serialize :partner_group_ids, Array
  
  accepts_nested_attributes_for :reader
  
  def has_group? id
    group_ids.to_a.map(&:to_i).include?(id)
  end
  
  def partner_has_group? id
    couple? && (
      partner_group_ids.to_a.map(&:to_i).include?(id) || !Group.find(id).is_conference_day_option?
    )
  end
  
  def day_groups
    Group.find_all_by_id(group_ids, :conditions => ["ancestry = ?", Group.conference_groups_holder.id.to_s])
  end
  
  def day_option_groups
    Group.find_all_by_id(group_ids, :conditions => ["ancestry like ?", "#{Group.conference_groups_holder.id}/%"])
  end
  
  def partner_day_option_groups
    Group.find(partner_group_ids)
  end
  
  def registered_for_groups
    day_groups.map{|g| [g, g.children.find_all_by_id(day_option_groups)]}.flatten
  end
  
  def partner_registered_for_groups
    day_groups.map{|g| [g, g.children.find_all_by_id(partner_day_option_groups)]}.flatten
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
