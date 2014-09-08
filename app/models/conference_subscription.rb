class ConferenceSubscription < ActiveRecord::Base
  belongs_to :reader
  has_many :groups
end
