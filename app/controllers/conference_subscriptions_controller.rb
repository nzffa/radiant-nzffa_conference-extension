class ConferenceSubscriptionsController < ReaderActionController
  
  def new
    @conference_subscription = current_reader.build_conference_subscription
  end
  
end
