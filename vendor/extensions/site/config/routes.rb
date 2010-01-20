map.resource :home_page
map.root :controller => :home_page, :action => :show

map.namespace :admin do |admin|
   admin.resources :products, :member => {:additional_fields => :get}
   admin.resource  :suspicious_order_settings
end
