module ConferenceSubscriptionsHelper
  def conference_group
    Group.find((Radiant::Config['conference_group_id']|| 257).to_i)
  end

  def render_conference_group_node(group, locals = {})
    @current_node = group
    locals.reverse_merge!(:level => 0, :simple => false).merge!(:group => group)
    render :partial => 'conference_subscriptions/conference_group_node', :locals =>  locals
  end
end
