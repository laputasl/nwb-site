map.namespace :admin do |admin|
   admin.resources :products, :member => {:additional_fields => :get}
    
end  
