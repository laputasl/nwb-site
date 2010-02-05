map.resource :home_page
map.root :controller => :home_page, :action => :show

map.resources :orders, :member => {:calculate_shipping => :get}
map.namespace :admin do |admin|
   admin.resources :products, :member => {:additional_fields => :get}
   admin.resource  :suspicious_order_settings
end

map.brand_taxon '/b/*path', :controller => 'taxons', :action => 'show'
map.brand_taxon '/c/*path', :controller => 'taxons', :action => 'show'