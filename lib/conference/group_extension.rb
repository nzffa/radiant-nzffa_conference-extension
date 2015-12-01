module Conference::GroupExtension
  def self.included(klass)
    klass.class_eval do
      def self.conference_groups
        self.conference_groups_holder.try(:children) || []
      end
      
      def self.conference_groups_holder
        begin
          find(Radiant::Config['conference.root_group_id'])
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end
    end
  end
  
  def is_conference_group?
    (ancestors << self).include? Group.conference_groups_holder
  end
  
  def is_conference_day_option?
    is_conference_group? && parent && !parent.parent_id.nil?
  end
  
end
