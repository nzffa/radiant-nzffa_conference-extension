ActionController::Routing::Routes.draw do |map|
  map.resources :conference_subscriptions
  # map.namespace :admin, :member => { :remove => :get } do |admin|
  #   admin.resources :conference
  # end
end