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
end