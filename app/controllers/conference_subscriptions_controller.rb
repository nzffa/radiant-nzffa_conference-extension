class ConferenceSubscriptionsController < ReaderActionController
  
  def new
    @conference_subscription = current_reader.build_conference_subscription
  end
  
  def create
    # target_group_ids = params[:conference_subscription][:group_ids].delete
    subscription = current_reader.build_conference_subscription(params[:conference_subscription])
    if subscription.valid?
      subscription.save
      
      # target_group_ids.map{|id| Group.find id }.each do |group|
        # current_reader.groups << group unless current_reader.is_in? group
      # end
      
    else
      @flash[:error] = 'Something went wrong with your subscription'
    end
    
  end
end
