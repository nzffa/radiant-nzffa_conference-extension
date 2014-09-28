module Conference::GroupExtension
  def is_conference_group?
    conference_group = Group.find(Radiant::Config['conference_group_id'])
    return (self == conference_group || self.ancestors.include?(conference_group))
  end
end