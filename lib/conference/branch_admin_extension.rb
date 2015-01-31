module Conference::BranchAdminExtension
  
  def self.included(klass)
    klass.class_eval do
      def render_csv_of_readers_with_conference_hook
        if RUBY_VERSION =~ /1.9/
          require 'csv'
          csv_lib = CSV
        else
          csv_lib = FasterCSV
        end
        if @group.is_conference_group?
          csv_string = csv_lib.generate do |csv|
            csv << %w[nzffa_membership_id name email phone postal_address post_city paid_by date_paid registrants levy notes do_not_publish_contact_details first_conference pickup_from_incoming_flight pickups_from_to_conference registered_for full_registration day_options]
            @readers.each do |r|
              next unless r.conference_subscription
              if !r.conference_subscription.couple? || r.conference_subscription.group_ids.map(&:to_i).include?(@group.id)
                csv << [r.nzffa_membership_id, r.name, r.email, r.phone, r.postal_address_string, r.post_city, r.conference_subscription.try(:payment_method), r.conference_subscription.try(:paid_at).try(:strftime, "%b %d"), r.conference_subscription.try(:single_or_couple) == 'couple' ? 2 : 1, r.conference_subscription.try(:levy), r.conference_subscription.try(:notes), r.conference_subscription.try(:do_not_publish_contact_details), r.conference_subscription.try(:first_conference), r.conference_subscription.try(:pickup_from_incoming_flight), r.conference_subscription.try(:pickups_from_to_conference), r.groups.select{|g| g.is_conference_group? && r.conference_subscription.group_ids.map(&:to_i).include?(g.id)}.map{|g| g.name }.join(", "), r.groups.include?(@template.conference_group) ? "Full" : "Partial", r.groups.select{|g| g.is_conference_day_option? && r.conference_subscription.group_ids.include?(g.id)}.map{|g| g.name}.join(", ") ]
              end
              if r.conference_subscription.couple? && (r.conference_subscription.partner_group_ids.try(:include?, @group.id) || [@group.id, @group.parent_id].include?(Radiant::Config['conference_group_id'].to_i))
                # Add row for partner;
                options_string = r.conference_subscription.partner_group_ids.nil? ? r.groups.select{|g| g.is_conference_day_option?}.map{|g| g.name}.join(", ") : Group.find(r.conference_subscription.partner_group_ids).map{|g| g.name}.join(", ")
                csv << [r.nzffa_membership_id, r.conference_subscription.partner_name, r.email, r.phone, r.postal_address_string, r.post_city, r.conference_subscription.try(:payment_method), r.conference_subscription.try(:paid_at).try(:strftime, "%b %d"), r.conference_subscription.try(:single_or_couple) == 'couple' ? 2 : 1, r.conference_subscription.try(:levy), r.conference_subscription.try(:notes), r.conference_subscription.try(:do_not_publish_contact_details), r.conference_subscription.try(:first_conference), r.conference_subscription.try(:pickup_from_incoming_flight), r.conference_subscription.try(:pickups_from_to_conference), r.groups.select{|g| g.is_conference_group? && (!g.is_conference_day_option? || r.conference_subscription.partner_group_ids.to_a.map(&:to_i).include?(g.id)) }.map{|g| g.name }.join(", "), r.groups.include?(@template.conference_group) ? "Full" : "Partial", options_string ]
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
          columns = %w(nzffa_membership_id name email phone postal_address post_city payment_method date_paid registrants levy notes do_not_publish_contact_details first_conference pickup_from_incoming_flight pickups_from_to_conference registered_for full_registration day_options)
          require 'spreadsheet'
          book = Spreadsheet::Workbook.new
          sheet = book.create_worksheet :name => 'Readers export'
          
          sheet.row(0).replace(["#{@group.name} downloaded #{Time.now.strftime("%Y-%m-%d")}"])
          sheet.row(1).replace(columns.map{|k| k.capitalize})
          
          next_row_index = 2
          
          @readers.select{|r| r.conference_subscription }.each do |reader|
            if !reader.conference_subscription.couple? || reader.conference_subscription.group_ids.map(&:to_i).include?(@group.id)
              sheet.row(next_row_index).replace(columns.map do |k|
                case k
                when 'payment_method', 'notes', 'levy', 'do_not_publish_contact_details', 'first_conference', 'pickup_from_incoming_flight', 'pickups_from_to_conference' then reader.conference_subscription.try(:send, k).to_s
                when 'date_paid' then reader.conference_subscription.try(:paid_at).try(:strftime, "%b %d")
                when 'registrants' then reader.conference_subscription.try(:single_or_couple) == 'couple' ? 2 : 1
                when 'postal_address' then reader.postal_address_string
                when 'registered_for' then reader.groups.select{|g| g.is_conference_group? && reader.conference_subscription.group_ids.map(&:to_i).include?(g.id)}.map{|g| g.name}.join(", ")
                when 'full_registration' then
                  reader.groups.include?(@template.conference_group) ? "Full" : "Partial"
                when 'day_options' then
                  reader.groups.select{|g| g.is_conference_day_option? && reader.conference_subscription.group_ids.include?(g.id)}.map{|g| g.name}.join(", ")
                else
                  reader.send(k)
                end
              end)
              next_row_index += 1
            end
            if reader.conference_subscription.couple? && (reader.conference_subscription.partner_group_ids.try(:include?, @group.id) || [@group.id, @group.parent_id].include?(Radiant::Config['conference_group_id'].to_i))
              # Add partner row
              sheet.row(next_row_index).replace(columns.map do |k|
                case k
                when 'payment_method', 'notes', 'levy', 'do_not_publish_contact_details', 'first_conference', 'pickup_from_incoming_flight', 'pickups_from_to_conference' then reader.conference_subscription.try(:send, k).to_s
                when 'date_paid' then reader.conference_subscription.try(:paid_at).try(:strftime, "%b %d")
                when 'registrants' then reader.conference_subscription.try(:single_or_couple) == 'couple' ? 2 : 1
                when 'postal_address' then reader.postal_address_string
                when 'registered_for' then reader.groups.select{|g| g.is_conference_group? && (!g.is_conference_day_option? || reader.conference_subscription.partner_group_ids.to_a.map(&:to_i).include?(g.id))}.map{|g| g.name}.join(", ")
                when 'full_registration' then
                  reader.groups.include?(@template.conference_group) ? "Full" : "Partial"
                when 'day_options' then
                  if reader.conference_subscription.partner_group_ids.nil?
                    reader.groups.select{|g| g.is_conference_day_option?}.map{|g| g.name}.join(", ")
                  else
                    Group.find(reader.conference_subscription.partner_group_ids).map{|g| g.name}.join(", ")
                  end
                when 'name'
                  reader.conference_subscription.partner_name
                else
                  reader.send(k)
                end
              end)
              next_row_index += 1
            end
            
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