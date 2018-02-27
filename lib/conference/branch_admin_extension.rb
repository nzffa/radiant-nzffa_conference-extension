module Conference::BranchAdminExtension
  
  def self.included(klass)
    klass.class_eval do
  
      def edit_with_conference_hook
        edit_without_conference_hook
        if @group.is_conference_group?
          render :edit_for_conference and return
        end
      end
      alias_method_chain :edit, :conference_hook
      
      def index_with_conference_hook
        @group = Group.find(params[:group_id])
        if @group.is_conference_group?
          @readers = @group.readers.select{|r| r.conference_subscription }
          @count = @readers.map{|r|
            if r.conference_subscription.has_group?(@group.id) && r.conference_subscription.partner_has_group?(@group.id)
              2
            else
              1
            end}.sum
          
          respond_to do |format|
            format.html { render :index_for_conference }
            format.csv { render_csv_of_readers_with_conference_hook }
            format.xls { render_xls_of_readers_with_conference_hook }
          end
        else
          index_without_conference_hook
        end
      end
      alias_method_chain :index, :conference_hook
      
      def require_branch_secretary_with_conference_hook
        require_reader
        @group = Group.find(params[:group_id])
        if !@group.is_conference_group?
          require_branch_secretary_without_conference_hook
        else
          unless Group.conference_groups_holder.homepage.try(:field, 'registrar_access_reader_ids').try(:content).to_s.split(',').map(&:to_i).include? current_reader.id
            raise ReaderError::AccessDenied, 'You must be specified as a conference registrar to access this page'
          end
        end
      end
      alias_method_chain :require_branch_secretary, :conference_hook
      
      def render_csv_of_readers_with_conference_hook
        if RUBY_VERSION =~ /1.9/
          require 'csv'
          csv_lib = CSV
        else
          csv_lib = FasterCSV
        end
        if @group.is_conference_group?
          csv_string = csv_lib.generate do |csv|
            csv << %w[nzffa_membership_id name email phone postal_address post_city paid_by date_paid levy notes do_not_publish_contact_details first_conference pickup_from_incoming_flight pickups_from_to_conference registered_for full_registration]
            @readers.each do |r|
              next unless r.conference_subscription
              if r.conference_subscription.has_group?(@group.id)
                name = r.conference_subscription.member_name.blank? ? r.name : r.conference_subscription.member_name
                payment_method = r.conference_subscription.payment_method
                payment_method.concat " (#{r.conference_subscription.id})" if payment_method == 'online'
                csv << [r.nzffa_membership_id, name, r.email, r.phone, r.postal_address_string, r.post_city, payment_method, r.conference_subscription.try(:paid_at).try(:strftime, "%b %d"), r.conference_subscription.try(:paid_amount), r.conference_subscription.try(:notes), r.conference_subscription.try(:do_not_publish_contact_details), r.conference_subscription.try(:first_conference), r.conference_subscription.try(:pickup_from_incoming_flight), r.conference_subscription.try(:pickups_from_to_conference), r.conference_subscription.try(:registered_for_groups).map{|g| g.name }.join(", "), r.groups.include?(Group.conference_groups_holder) ? "Full" : "Partial" ]
              end
              if r.conference_subscription.couple? && r.conference_subscription.partner_has_group?(@group.id)
                # Add row for partner;
                payment_method = r.conference_subscription.payment_method
                payment_method.concat " (#{r.conference_subscription.id})" if payment_method == 'online'
                csv << [r.nzffa_membership_id, r.conference_subscription.partner_name, r.email, r.phone, r.postal_address_string, r.post_city, payment_method, r.conference_subscription.try(:paid_at).try(:strftime, "%b %d"), r.conference_subscription.try(:paid_amount), "", r.conference_subscription.try(:do_not_publish_contact_details), r.conference_subscription.try(:first_conference), r.conference_subscription.try(:pickup_from_incoming_flight), r.conference_subscription.try(:pickups_from_to_conference), r.conference_subscription.try(:partner_registered_for_groups).to_a.map{|g| g.name }.join(", "), r.groups.include?(Group.conference_groups_holder) ? "Full" : "Partial" ]
              end
            end
          end
          
          headers["Content-Type"] ||= 'text/csv'
          headers["Content-Disposition"] = "attachment; filename=\"#{@group.name}_#{action_name}_#{DateTime.now.to_s}\".csv"
          render :text => csv_string
        else
          render_csv_of_readers_without_conference_hook
        end
      end
      alias_method_chain :render_csv_of_readers, :conference_hook
      
      def render_xls_of_readers_with_conference_hook
        if @group.is_conference_group?
          columns = %w(nzffa_membership_id name email phone postal_address post_city payment_method date_paid levy notes do_not_publish_contact_details first_conference pickup_from_incoming_flight pickups_from_to_conference registered_for full_registration)
          require 'spreadsheet'
          book = Spreadsheet::Workbook.new
          sheet = book.create_worksheet :name => 'Readers export'
          
          sheet.row(0).replace(["#{@group.name} subscriptions (#{@count}) downloaded #{Time.now.strftime("%Y-%m-%d")}"])
          sheet.row(1).replace(columns.map{|k| k.capitalize})
          
          next_row_index = 2
          
          @readers.each do |reader|
            if !reader.conference_subscription.couple? || reader.conference_subscription.group_ids.map(&:to_i).include?(@group.id)
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
                when 'registered_for' then reader.conference_subscription.try(:registered_for_groups).to_a.map{|g| g.name}.join(", ")
                when 'full_registration' then
                  reader.groups.include?(Group.conference_groups_holder) ? "Full" : "Partial"
                when 'name' then
                  reader.conference_subscription.member_name.blank? ? reader.name : reader.conference_subscription.member_name
                else
                  reader.send(k)
                end
              end)
              next_row_index += 1
            end
            if reader.conference_subscription.couple? && reader.conference_subscription.partner_has_group?(@group.id)
              # Add partner row
              sheet.row(next_row_index).replace(columns.map do |k|
                case k
                when 'notes', 'do_not_publish_contact_details', 'first_conference', 'pickup_from_incoming_flight', 'pickups_from_to_conference' then reader.conference_subscription.try(:send, k).to_s
                when 'payment_method' then
                  payment_method = reader.conference_subscription.payment_method
                  payment_method.concat " (#{reader.conference_subscription.id})" if payment_method == 'online'
                  payment_method
                when 'levy' then ""
                when 'date_paid' then reader.conference_subscription.try(:paid_at).try(:strftime, "%b %d")
                when 'postal_address' then reader.postal_address_string
                when 'registered_for' then reader.conference_subscription.registered_for_groups.map{|g| g.name}.join(", ")
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
    
          filename = "#{@group.name} (#{@count})-#{Time.now.strftime("%Y-%m-%d")}.xls"
          tmp_file = Tempfile.new(filename)
          book.write tmp_file.path
          send_file tmp_file.path, :filename => filename
        else
          render_xls_of_readers_without_conference_hook
        end
      end
      alias_method_chain :render_xls_of_readers, :conference_hook
    end
  end
end