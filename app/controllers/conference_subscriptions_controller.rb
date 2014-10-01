class ConferenceSubscriptionsController < ReaderActionController
  helper :reader
  def new
    @conference_subscription = current_reader.conference_subscription || current_reader.build_conference_subscription
  end
  
  def create
    # target_group_ids = params[:conference_subscription][:group_ids].delete
    subscription.update_attributes(params[:conference_subscription])
    if subscription.valid?
      subscription.levy = 0
      
      reader.memberships.select{|m| m.group.is_conference_group?}.each{|m| m.destroy}
    
      params["group_ids"].each do |id|
        group = Group.find(id)
        unless !group.is_conference_group?
          reader.groups << group 
          subscription.levy += group.conference_price.to_i
          # look for day options
          if id = params["conference_day_#{group.id}_option"]
            group = Group.find(id)
            reader.groups << group
            subscription.levy += group.conference_price.to_i
          end
        end
        
      end
      subscription.save      
    else
      @flash.now[:error] = 'Something went wrong with your subscription'
    end
    
    if reader == current_reader
      redirect_to membership_details_path
    else
      redirect_to branch_admin_path(@template.conference_group)
    end
  end

  
  def update
    # if @conference_subscription.paid?
    # else
      subscription.update_attributes(params[:conference_subscription])
      subscription.levy = 0
      # Reset conference groups
      reader.memberships.select{|m| m.group.is_conference_group?}.each{|m| m.destroy}
    
      params["group_ids"].each do |id|
        group = Group.find(id)
        unless !group.is_conference_group?
          reader.groups << group
          subscription.levy += group.conference_price.to_i
          # look for day options
          if id = params["conference_day_#{group.id}_option"]
            group = Group.find(id)
            reader.groups << group
            subscription.levy += group.conference_price.to_i
          end
        end
        
      end
      subscription.save
      flash.now[:notice] = "Your conference subscription has been updated"
      
    # end
    if reader == current_reader
      redirect_to membership_details_path
    else
      redirect_to branch_admin_path(@template.conference_group)
    end
  end
  
  def pay_online
    conference_subscription = ConferenceSubscription.find params[:id]
    redirect_to PxPayParty.payment_url_for(:amount => conference_subscription.levy,
                                           :merchant_reference => "ConferenceSubscription:#{conference_subscription.id}",
                                           :return_url => payment_finished_conference_subscription_url)
    
  end
  
  def payment_finished
    result = PxPayParty.payment_response(params[:result])
    id = result['MerchantReference'].split(':')[1]
    conference_subscription = ConferenceSubscription.find(id)

    if result['Success'] == '1'
      conference_subscription.paid_amount = result['AmountSettlement']
      conference_subscription.paid_at = Time.now
      conference_subscription.save
      render :success
    else
      render :failure
    end
  end
  
  def reader
    @reader ||= Reader.find(params[:conference_subscription][:reader_id]|| current_reader.id)
  end
  
  def subscription
    @subscription ||= reader.conference_subscription || reader.build_conference_subscription
  end
end
