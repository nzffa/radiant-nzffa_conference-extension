class ConferenceSubscriptionsController < ReaderActionController
  helper :reader
  def new
    @conference_subscription = current_reader.conference_subscription || current_reader.build_conference_subscription
  end
  
  def create
    reader = Reader.find(params[:conference_subscription][:reader_id]|| current_reader.id)
    # target_group_ids = params[:conference_subscription][:group_ids].delete
    subscription = reader.build_conference_subscription(params[:conference_subscription])
    if subscription.valid?
      subscription.save
      
      reader.memberships.select{|m| m.group.is_conference_group?}.each{|m| m.destroy}
    
      params["group_ids"].each do |id|
        group = Group.find(id)
        unless !(group.ancestors.include?(@template.conference_group) or
            group == @template.conference_group)
          reader.groups << group 
          # look for day options
          if id = params["conference_day_#{group.id}_option"]
            group = Group.find(id)
            reader.groups << group
          end
        end
        
      end
      
    else
      @flash[:error] = 'Something went wrong with your subscription'
    end
    if reader == current_reader
      redirect_to membership_details_path
    else
      redirect_to branch_admin_path(@template.conference_group)
    end
  end
  
  def update
    reader = Reader.find(params[:conference_subscription][:reader_id]|| current_reader.id)
    @conference_subscription = reader.conference_subscription
    # if @conference_subscription.paid?
    # else
      @conference_subscription.update_attributes(params[:conference_subscription])
      # Reset conference groups
      reader.memberships.select{|m| m.group.is_conference_group?}.each{|m| m.destroy}
    
      params["group_ids"].each do |id|
        group = Group.find(id)
        unless !group.is_conference_group?
          reader.groups << group 
          # look for day options
          if id = params["conference_day_#{group.id}_option"]
            group = Group.find(id)
            reader.groups << group
          end
        end
        
      end
      flash[:notice] = "Your conference subscription has been updated"
      
    # end
    if reader == current_reader
      redirect_to membership_details_path
    else
      redirect_to branch_admin_path(@template.conference_group)
    end
  end
  
end
