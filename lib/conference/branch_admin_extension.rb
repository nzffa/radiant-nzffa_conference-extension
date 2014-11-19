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
            csv << %w[nzffa_membership_id name email phone postal_address paid_by date_paid registrants levy notes]
            @readers.each do |r|
              csv << [r.nzffa_membership_id, r.name, r.email, r.phone, r.postal_address_string, r.conference_subscription.try(:payment_method), r.conference_subscription.try(:paid_at).try(:strftime, "%b %d"), r.conference_subscription.try(:single_or_couple) == 'couple' ? 2 : 1, r.conference_subscription.try(:levy), r.conference_subscription.try(:notes)]
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
          columns = %w(nzffa_membership_id name email phone postal_address payment_method date_paid registrants levy notes)
          require 'spreadsheet'
          book = Spreadsheet::Workbook.new
          sheet = book.create_worksheet :name => 'Readers export'
        
          sheet.row(0).replace(columns.map{|k| k.capitalize})
    
          @readers.each_with_index do |reader, i|
            sheet.row(i+1).replace(columns.map do |k|
              case k
              when 'payment_method', 'notes', 'levy' then reader.conference_subscription.try(:send, k)
              when 'date_paid' then reader.conference_subscription.try(:paid_at).try(:strftime, "%b %d")
              when 'registrants' then reader.conference_subscription.try(:single_or_couple) == 'couple' ? 2 : 1
              else
                reader.send(k)
              end
            end)
          end
    
          filename = 'readers_export'
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