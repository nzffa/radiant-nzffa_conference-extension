class ConferenceSubscriptionsController < ReaderActionController
  
  def new
    @conference_subscription = current_reader.conference_subscription || current_reader.build_conference_subscription
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
  
  def update
    @conference_subscription = current_reader.conference_subscription
    # if @conference_subscription.paid?
    # else
      @conference_subscription.update_attributes(params[:conference_subscription])
      # Reset conference groups
      current_reader.memberships.select{|m| m.group.ancestors.include?(conference_group) || m.group == conference_group}.each{|m| m.destroy}
    
      params["group_ids"].each do |id|
        group = Group.find(id)
        unless !group.ancestors.include?(conference_group)
          current_reader.groups << group 
          # look for day options
          if id = params["conference_day_#{group.id}_option"]
            group = Group.find(id)
            current_reader.groups << group unless !group.ancestors.include?(conference_group)
          end
        end
        
      end
      flash[:notice] = "Your conference subscription has been updated"
      
    # end
    redirect_to membership_details_path
  end
  
  def conference_group
    Group.find((Radiant::Config['conference_group_id']|| 257).to_i)
  end  
  helper_method :conference_group
end
