module Conference::ReaderExtension
  def self.included(base)
    base.send(:has_one, :conference_subscription)
  end
  
  def is_registered_for_conference?
    conference_subscription && (conference_subscription.levy == conference_subscription.paid_amount)
  end
end