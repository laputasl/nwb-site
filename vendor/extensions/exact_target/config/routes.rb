map.namespace :admin do |admin|
  admin.resources :exact_target_lists, :collection => {:get_lists => :get}
end
