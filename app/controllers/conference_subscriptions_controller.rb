class ConferenceSubscriptionsController < ReaderActionController
  helper :reader
  before_filter :subscription, :only => [:new, :edit]
  
  def create
    # target_group_ids = params[:conference_subscription][:group_ids].delete
    subscription.update_attributes(params[:conference_subscription])
    if subscription.valid?
      subscription.levy = 0
      
      subscription.group_ids.each do |id|
        group = Group.find(id)
        unless !group.is_conference_group?
          subscription.levy += group.conference_price.to_i
          # look for day options
          if id = params["conference_day_#{id}_option"]
            group = Group.find(id)
            subscription.levy += group.conference_price.to_i
            subscription.group_ids << id
          end
        end
      end
      
      subscription.save      
    else
      @flash.now[:error] = 'Something went wrong with your subscription'
    end
    
    if reader == current_reader
      redirect_to pay_online_conference_subscription_path(subscription)
    else
      redirect_to branch_admin_path(@template.conference_group)
    end
  end

  def edit
    render :new
  end
  
  def update
    # if @conference_subscription.paid?
    # else
      subscription.update_attributes(params[:conference_subscription])
      subscription.levy = 0
      # Reset conference groups
      reader.memberships.select{|m| m.group.is_conference_group?}.each{|m| m.destroy}
    
      subscription.group_ids.each do |id|
        group = Group.find(id)
        unless !group.is_conference_group?
          subscription.levy += group.conference_price.to_i
          # look for day options
          if id = params["conference_day_#{id}_option"]
            group = Group.find(id)
            subscription.levy += group.conference_price.to_i
            subscription.group_ids << id
          end
        end
      end
      
      subscription.save
      flash.now[:notice] = "Your conference subscription has been updated"
    # end
    if reader == current_reader
      redirect_to pay_online_conference_subscription_path(subscription)
    else
      redirect_to branch_admin_path(@template.conference_group)
    end
  end
  
  def invite
    if nzffa_id = params[:nzffa_id] and !nzffa_id.blank?
      reader = Reader.find_by_nzffa_membership_id(nzffa_id)
      redirect_to branch_admin_edit_path(Radiant::Config['conference_group_id'], reader.nzffa_membership_id) unless reader.nil?
    end
    if name = params[:name] and !name.blank?
      @readers = Reader.all(:conditions => ["surname LIKE :name OR forename LIKE :name", {:name => "%#{name}%"}])
    end
    if email = params[:email] and !email.blank?
      @readers = Reader.all(:conditions => ["email LIKE %?%", name])
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
      
      conference_subscription.group_ids.each do |id|
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
      
      conference_subscription.save
      render :paid
    else
      flash[:error] = "Your online payment did not come through. Please try again."
      render :new
    end
  end
  
  def reader
    @reader ||= Reader.find(params[:conference_subscription] ? params[:conference_subscription][:reader_id] : current_reader.id)
  end
  
  def subscription
    @subscription ||= (reader.conference_subscription || reader.build_conference_subscription)
  end
end
