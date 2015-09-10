Radiant.config do |config|
  config.namespace('conference') do |conference|
    conference.define 'root_group_id', :select_from => lambda {Group.all.map{|l| [l.name, l.id.to_s]}}, :allow_blank => true
  end
end
