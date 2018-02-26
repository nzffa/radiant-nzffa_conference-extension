class ConferenceSubscriptionsController < ReaderActionController
  helper :reader
  before_filter :subscription, :only => [:new, :edit, :receipt]
  before_filter :require_secretary_access, :only => [:index, :destroy]
  skip_before_filter :require_reader, :only => :payment_finished
  
  def index
    @readers = Reader.in_groups([Group.conference_groups_holder] + Group.conference_groups).select{|r| r.conference_subscription }
    @count = @readers.map{|r| r.conference_subscription.couple? ? 2 : 1}.sum
    
    respond_to do |format|
      format.xls do
        columns = %w(nzffa_membership_id name email phone postal_address post_city payment_method date_paid levy notes do_not_publish_contact_details first_conference pickup_from_incoming_flight pickups_from_to_conference registered_for full_registration)
        require 'spreadsheet'
        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet :name => 'Readers export'
        sheet.row(0).replace(["All conference subscriptions (#{@count}) - downloaded #{Time.now.strftime("%Y-%m-%d")}"])
        sheet.row(1).replace(columns.map{|k| k.capitalize})
        next_row_index = 2
        
        @readers.each_with_index do |reader, i|
          sheet.row(next_row_index).replace(columns.map do |k|
            case k
            when 'notes', 'do_not_publish_contact_details', 'first_conference', 'pickup_from_incoming_flight', 'pickups_from_to_conference' then reader.conference_subscription.try(:send, k).to_s
            when 'payment_method' then
              payment_method = reader.conference_subscription.payment_method
              payment_method.concat " (#{reader.conference_subscription.id})" if payment_method == 'online'
              payment_method
            when 'levy' then reader.conference_subscription.try(:paid_amount)
            when 'date_paid' then reader.conference_subscription.try(:paid_at).try(:strftime, "%b %d")
            when 'postal_address' then reader.postal_address_string
            when 'registered_for' then reader.conference_subscription.registered_for_groups.map{|g| g.name}.join(", ")
            when 'full_registration' then
              reader.groups.include?(Group.conference_groups_holder) ? "Full" : "Partial"
            when 'day_options' then
              reader.conference_subscription.day_option_groups.join(', ')
            when 'name' then
              reader.conference_subscription.member_name.blank? ? reader.name : reader.conference_subscription.member_name
            else
              reader.send(k)
            end
          end)
          next_row_index += 1
          if reader.conference_subscription.couple?
            # Add partner row
            sheet.row(next_row_index).replace(columns.map do |k|
              case k
              when 'notes', 'do_not_publish_contact_details', 'first_conference', 'pickup_from_incoming_flight', 'pickups_from_to_conference' then reader.conference_subscription.try(:send, k).to_s
              when 'payment_method'
                payment_method = reader.conference_subscription.payment_method
                payment_method.concat " (#{reader.conference_subscription.id})" if payment_method == 'online'
                payment_method
              when 'levy' then ""
              when 'date_paid' then reader.conference_subscription.try(:paid_at).try(:strftime, "%b %d")
              when 'postal_address' then reader.postal_address_string
              when 'registered_for' then reader.conference_subscription.partner_registered_for_groups.map{|g| g.name}.join(", ")
              when 'full_registration' then
                reader.groups.include?(Group.conference_groups_holder) ? "Full" : "Partial"
              when 'name'
                reader.conference_subscription.partner_name
              else
                reader.send(k)
              end
            end)
            next_row_index += 1
          end
          
        end
  
        filename = "All conference subscriptions (#{@count})-#{Time.now.strftime("%Y-%m-%d")}.xls"
        tmp_file = Tempfile.new(filename)
        book.write tmp_file.path
        send_file tmp_file.path, :filename => filename
      end
      format.csv do
        if RUBY_VERSION =~ /1.9/
          require 'csv'
          csv_lib = CSV
        else
          csv_lib = FasterCSV
        end
        csv_string = csv_lib.generate do |csv|
          csv << %w[nzffa_membership_id name email phone postal_address post_city paid_by date_paid levy notes do_not_publish_contact_details first_conference pickup_from_incoming_flight pickups_from_to_conference registered_for full_registration]
          @readers.each do |r|
            name = r.conference_subscription.member_name.blank? ? r.name : r.conference_subscription.member_name
            csv << [r.nzffa_membership_id, name, r.email, r.phone, r.postal_address_string, r.post_city, r.conference_subscription.try(:payment_method), r.conference_subscription.try(:paid_at).try(:strftime, "%b %d"), r.conference_subscription.try(:paid_amount), r.conference_subscription.try(:notes), r.conference_subscription.try(:do_not_publish_contact_details), r.conference_subscription.try(:first_conference), r.conference_subscription.try(:pickup_from_incoming_flight), r.conference_subscription.try(:pickups_from_to_conference), r.conference_subscription.try(:registered_for_groups).to_a.map{|g| g.name }.join(", "), r.groups.include?(Group.conference_groups_holder) ? "Full" : "Partial"]
              
            if r.conference_subscription.couple?
              # Add row for partner;
              csv << [r.nzffa_membership_id, r.conference_subscription.partner_name, r.email, r.phone, r.postal_address_string, r.post_city, r.conference_subscription.try(:payment_method), r.conference_subscription.try(:paid_at).try(:strftime, "%b %d"), r.conference_subscription.try(:paid_amount), "", r.conference_subscription.try(:do_not_publish_contact_details), r.conference_subscription.try(:first_conference), r.conference_subscription.try(:pickup_from_incoming_flight), r.conference_subscription.try(:pickups_from_to_conference), r.conference_subscription.try(:partner_registered_for_groups).to_a.map{|g| g.name }.join(", "), r.groups.include?(Group.conference_groups_holder) ? "Full" : "Partial" ]
            end
          end
        end

        headers["Content-Type"] ||= 'text/csv'
        headers["Content-Disposition"] = "attachment; filename=\"All conference subscriptions (#{@count})-#{DateTime.now.to_s}.csv\""
        render :text => csv_string
      end
      format.html do
        
      end
    end
  end
  
  def create
    # target_group_ids = params[:conference_subscription][:group_ids].delete
    subscription.update_attributes(params[:conference_subscription])
    if subscription.valid?
      update_subscription_levy_and_group_ids_from_params(subscription, params)
      if !subscription.paid? && subscription.paid_amount > 0
        subscription.update_attribute(:paid_at, Time.now)
      end
      if subscription.paid?
        subscription.group_ids.map{ |gid|
          reader.groups << Group.find(gid)
        }
        subscription.partner_group_ids.map{ |gid|
          reader.groups << Group.find(gid)
        }
        subscription.paid_at ||= Time.now
      end
      
      subscription.save      
    else
      flash[:error] = 'Something went wrong with your subscription'
    end
    
    if reader == current_reader
      redirect_to subscription.paid? ? :edit : pay_online_conference_subscription_path(subscription)
    else
      redirect_to conference_subscriptions_path
    end
  end
  
  def receipt
    render :layout => false
  end

  def edit
    reader
    (redirect_to(:back) and return) if @subscription.paid_online? && !reader.is_secretary?
    render :new
  end
  
  def update
    subscription.update_attributes(params[:conference_subscription])
    update_subscription_levy_and_group_ids_from_params(subscription, params)
    if !subscription.paid? && subscription.paid_amount > 0
      subscription.update_attribute(:paid_at, Time.now)
    end
    if subscription.paid?
      subscription.reader.memberships.select{|m| m.group && m.group.is_conference_group?}.each{|m| m.destroy}
      subscription.group_ids.map{ |gid|
        reader.groups << Group.find(gid)
      }
      subscription.partner_group_ids.map{ |gid|
        reader.groups << Group.find(gid)
      }
    end
        
    subscription.save
    flash[:notice] = "Your conference subscription has been updated"
    
    if !subscription.paid? && subscription.payment_method == 'online'
      redirect_to pay_online_conference_subscription_path(subscription)
    elsif current_reader.is_secretary?
      redirect_to branch_admin_path(Group.conference_groups_holder)
    else
      redirect_to :edit
    end
  end
  
  def destroy
    subscription = ConferenceSubscription.find(params[:id])
    if subscription.nil?
      flash[:error] = "Conference subscription not found"
    else
      subscription.reader.memberships.select{|m| m.group && m.group.is_conference_group?}.each{|m| m.destroy}
      subscription.destroy
    end
    redirect_to :back # branch_admin/:conference_id
  end
  
  def invite
    if nzffa_id = params[:nzffa_id] and !nzffa_id.blank?
      reader = Reader.find_by_nzffa_membership_id(nzffa_id)
      redirect_to branch_admin_edit_path(Group.conference_groups_holder.id, reader.nzffa_membership_id) unless reader.nil?
    end
    if name = params[:name] and !name.blank?
      @readers = Reader.all(:conditions => ["surname LIKE :name OR forename LIKE :name", {:name => "%#{name}%"}])
    end
    if email = params[:email] and !email.blank?
      @readers = Reader.all(:conditions => ["email LIKE ?", "%#{email}%"])
    end
  end
  
  def email
    @readers = Reader.in_groups([Group.conference_groups_holder] + Group.conference_groups).select{|r| r.conference_subscription }
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
    conference_subscription = ConferenceSubscription.find(params[:id])

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
      subscription
      reader
      render :new
    end
  end
  
  def reader
    @reader ||= if params[:conference_subscription]
      Reader.find(params[:conference_subscription][:reader_id])
    elsif params[:id]
      ConferenceSubscription.find(params[:id]).reader
    else
      current_reader
    end
  end
  
  def subscription
    if params[:id]
      @subscription = ConferenceSubscription.find(params[:id])
      require_secretary_access if @subscription.reader_id != current_reader.id
      @subscription
    else
      @subscription ||= (reader.conference_subscription || reader.conference_subscriptions.create(:conference_group_id => Group.conference_groups_holder.id))
    end
  end
  
  private
  def require_registrar_access
    unless current_reader &&
        Group.conference_groups_holder.try(:field, 'registrar_access_reader_ids').to_s.split(',').map(&:to_i).include? current_reader.id
      flash[:error] = "You do not have registrar access"
      redirect_to reader_dashboard_url and return
    end
  end
  
  def update_subscription_levy_and_group_ids_from_params(subscription, params)
    subscription.levy = 0
    option_group_ids = []
    partner_option_group_ids = []
    subscription.group_ids.map(&:to_i).each do |id|
      group = Group.find(id)
      unless !group.is_conference_group? 
        subscription.levy += group.conference_price.to_i
        if subscription.single_or_couple == 'couple'
          subscription.levy += group.conference_price.to_i
        end
        # look for day options
        if oid = params["conference_day_#{id}_option"]
          group = Group.find(oid)
          subscription.levy += group.conference_price.to_i
          option_group_ids << oid.to_i
        end
        # look for day options for partner if applicable
        if subscription.couple? && pid = params["conference_day_#{id}_partner_option"]
          group = Group.find(pid)
          subscription.levy += group.conference_price.to_i
          partner_option_group_ids << pid.to_i
        end
      end
    end
    subscription.group_ids.concat option_group_ids
    subscription.partner_group_ids = partner_option_group_ids
    
    if subscription.group_ids.map(&:to_i).include?(Group.conference_groups_holder.id) and Group.conference_groups_holder.conference_price.to_i > 0
      subscription.levy = Group.conference_groups_holder.conference_price.to_i
      subscription.levy *= 2 if subscription.couple?
      # After taking 'full conference' price, check for extra levy in day options
      subscription.levy += Group.find(subscription.group_ids).map(&:extra_levy).compact.sum
      # .. same for partner
      if subscription.couple?
        subscription.levy += Group.find(subscription.partner_group_ids).map(&:extra_levy).compact.sum
      end
    else
      # Also check the 'full conference' group for a day registration levy (even though it is not checked)
      subscription.levy += Group.conference_groups_holder.day_registration_fee
      subscription.levy += Group.conference_groups_holder.day_registration_fee if subscription.couple?
      # Check for day_registration_fees
      subscription.levy += Group.find(subscription.group_ids).map(&:day_registration_fee).compact.sum
      # Check for day_registration_fees for partner
      subscription.levy += Group.find(subscription.partner_group_ids).map(&:day_registration_fee).compact.sum
    end
    subscription.save
  end
end
