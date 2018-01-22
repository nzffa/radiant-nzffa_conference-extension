Radiant.config do |config|
  config.namespace('conference') do |conference|
    conference.define 'root_group_id', :select_from => lambda {Group.all.map{|l| [l.name, l.id.to_s]}}, :allow_blank => true
    conference.define 'ask_flight_info_for_pickup', :default => false, :type => :boolean
    conference.define 'receipt_label_flight_pickup', :default => 'Your arrival time and flight, for pickup from the airport:'
    conference.define 'receipt_label_hotel', :default => 'You will be staying at:'
  end
end
