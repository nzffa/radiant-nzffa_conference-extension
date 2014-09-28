module Conference::ReaderHelperExtension
  def render_group_node(group, locals = {})
    @current_node = group
    locals.reverse_merge!(:level => 0, :simple => false).merge!(:group => group)
    render :partial => 'conference_subscriptions/conference_node', :locals =>  locals
  end
end