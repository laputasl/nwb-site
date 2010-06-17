map.resource :home_page
map.root :controller => :home_page, :action => :show

#needed for pagination
map.products "/products", :controller => :products, :action => :index

map.resources :orders,  :member => {:calculate_shipping => :get}, :collection => {:add_variant_only => [:post, :get]} do |order|
  order.resource :checkout, :member => {:set_shipping_method => :any}
end

map.connect "/add_to_cart", :controller=> 'orders', :action=>"add_variant_only"


map.namespace :admin do |admin|
   admin.resources :products, :member => {:additional_fields => :get}
   admin.resource  :suspicious_order_settings
end

map.category_taxon '/c/*path', :controller => 'taxons', :action => 'show'
map.brand_taxon '/b/*path', :controller => 'taxons', :action => 'show'
# map.feed '/feed/:feed.:format',  :controller => 'feeds', :action => 'show'
# map.feed '/feed(/:store)/:feed.:format',  :controller => 'feeds', :action => 'show'

map.connect '/inc/:segment', :controller => 'feeds', :action => 'includes',  :conditions => { :method => :get } 
map.connect '/feed/:feed.:format', :controller => 'feeds', :action => 'show',  :conditions => { :method => :get } 
map.connect '/feed/:store/:feed.:format', :controller => 'feeds', :action => 'show',  :conditions => { :method => :get } 
