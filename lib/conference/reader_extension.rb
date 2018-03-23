module Conference::ReaderExtension
  def self.included(base)
    base.send(:has_many, :conference_subscriptions)
  end
  
  def conference_subscription
    conference_subscriptions.find_by_conference_group_id(Group.conference_groups_holder.id)
  end
  
  def is_registered_for_conference?
    conference_subscription && (conference_subscription.paid?)
  end
  
  def is_conference_registrar?
    Group.conference_groups_holder.homepage.try(:field, 'registrar_access_reader_ids').try(:content).to_s.split(',').map(&:to_i).include? id
  end
end