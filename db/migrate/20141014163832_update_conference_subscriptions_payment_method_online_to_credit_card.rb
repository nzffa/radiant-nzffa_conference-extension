class UpdateConferenceSubscriptionsPaymentMethodOnlineToCreditCard < ActiveRecord::Migration
  def self.up
    ConferenceSubscription.find_all_by_payment_method('online').each do |cs|
      cs.update_attribute :payment_method, 'credit-card'
    end
  end

  def self.down
    ConferenceSubscription.find_all_by_payment_method('credit-card').each do |cs|
      cs.update_attribute :payment_method, 'online'
    end
  end
end
