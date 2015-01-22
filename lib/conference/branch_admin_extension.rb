module Conference::BranchAdminExtension
  
  def self.included(klass)
    klass.class_eval do
      
      def edit_with_conference_hook
        Reader.find_by_nzffa_membership_id(params[:nzffa_membership_id]).conference_subscription.try(:paid_online?) ? redirect_to(branch_admin_path(@template.conference_group)) : edit_without_conference_hook
      end
      alias_method_chain :edit, :conference_hook
      
      def render_csv_of_readers_with_conference_hook
        if RUBY_VERSION =~ /1.9/
          require 'csv'
          csv_lib = CSV
        else
          csv_lib = FasterCSV
        end
        if @group.is_conference_group?
          csv_string = csv_lib.generate do |csv|
            csv << %w[nzffa_membership_id name email phone postal_address paid_by date_paid registrants levy notes do_not_publish_contact_details first_conference pickup_from_incoming_flight pickups_from_to_conference]
            @readers.each do |r|
              next unless r.conference_subscription
              csv << [r.nzffa_membership_id, r.name, r.email, r.phone, r.postal_address_string, r.conference_subscription.try(:payment_method), r.conference_subscription.try(:paid_at).try(:strftime, "%b %d"), r.conference_subscription.try(:single_or_couple) == 'couple' ? 2 : 1, r.conference_subscription.try(:levy), r.conference_subscription.try(:notes), r.conference_subscription.try(:do_not_publish_contact_details), r.conference_subscription.try(:first_conference), r.conference_subscription.try(:pickup_from_incoming_flight), r.conference_subscription.try(:pickups_from_to_conference)]
            end
          end
          
          headers["Content-Type"] ||= 'text/csv'
          headers["Content-Disposition"] = "attachment; filename=\"#{@group.name}_#{action_name}_#{DateTime.now.to_s}\""
          render :text => csv_string
        else
          render_csv_of_readers_without_conference_hook
        end
      end
      alias_method_chain :render_csv_of_readers, :conference_hook
      
      def render_xls_of_readers_with_conference_hook
        if @group.is_conference_group?
          columns = %w(nzffa_membership_id name email phone postal_address payment_method date_paid registrants levy notes do_not_publish_contact_details first_conference pickup_from_incoming_flight pickups_from_to_conference)
          require 'spreadsheet'
          book = Spreadsheet::Workbook.new
          sheet = book.create_worksheet :name => 'Readers export'
          
          sheet.row(0).replace(["#{@group.name} downloaded #{Time.now.strftime("%Y-%m-%d")}"])
          sheet.row(1).replace(columns.map{|k| k.capitalize})
          
          @readers.select{|r| r.conference_subscription }.each_with_index do |reader, i|
            sheet.row(i+2).replace(columns.map do |k|
              case k
              when 'payment_method', 'notes', 'levy', 'do_not_publish_contact_details', 'first_conference', 'pickup_from_incoming_flight', 'pickups_from_to_conference' then reader.conference_subscription.try(:send, k).to_s
              when 'date_paid' then reader.conference_subscription.try(:paid_at).try(:strftime, "%b %d")
              when 'registrants' then reader.conference_subscription.try(:single_or_couple) == 'couple' ? 2 : 1
              when 'postal_address' then reader.postal_address_string
              else
                reader.send(k)
              end
            end)
          end
    
          filename = "#{@group.name}-#{Time.now.strftime("%Y-%m-%d")}.xls"
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