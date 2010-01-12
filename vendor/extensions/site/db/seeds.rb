# Temporarily turn off SSL in production (for dev server)
Spree::Config.set(:allow_ssl_in_production => false)

Spree::Config.set(:exact_target_user => "NWB_API_USER")
Spree::Config.set(:exact_target_password => "vki1234!")

#Spree::Config.set("searcher.spelling_suggestion" => true)
