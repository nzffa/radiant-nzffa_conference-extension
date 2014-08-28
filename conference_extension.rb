# Uncomment this if you reference any of your controllers in activate
# require_dependency "application_controller"
require "radiant-conference-extension"

class ConferenceExtension < Radiant::Extension
  version     RadiantConferenceExtension::VERSION
  description RadiantConferenceExtension::DESCRIPTION
  url         RadiantConferenceExtension::URL

  # See your config/routes.rb file in this extension to define custom routes

  extension_config do |config|
    # config is the Radiant.configuration object
  end

  def activate
    # tab 'Content' do
    #   add_item "Conference", "/admin/conference", :after => "Pages"
    # end
  end
end
