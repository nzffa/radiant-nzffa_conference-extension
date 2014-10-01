ActionController::Routing::Routes.draw do |map|
  map.resources :conference_subscriptions, :member => { :pay_online => :get, :payment_finished => :get }
  
end