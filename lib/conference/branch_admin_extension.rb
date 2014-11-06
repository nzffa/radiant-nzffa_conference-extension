module Conference::BranchAdminExtension
  
  def self.included(klass)
    klass.class_eval do
      
      def edit_with_conference_hook
        Reader.find_by_nzffa_membership_id(params[:nzffa_membership_id]).conference_subscription.try(:paid_online?) ? redirect_to(branch_admin_path(@template.conference_group)) : edit_without_conference_hook
      end
      alias_method_chain :edit, :conference_hook
      
    end
  end
end