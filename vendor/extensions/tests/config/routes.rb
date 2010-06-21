# Put your extension routes here.

 map.namespace :admin do |admin|
   admin.resources :gwo_tests, :member => {:enable => :get, :disable => :get}
 end  