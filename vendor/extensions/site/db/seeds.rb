# Temporarily turn off SSL in production (for dev server)
Spree::Config.set(:allow_ssl_in_production => false)

Spree::Config.set(:exact_target_user => "NWB_API_USER")
Spree::Config.set(:exact_target_password => "vki1234!")

#Spree::Config.set("searcher.spelling_suggestion"  => true)

Spree::ActiveShipping::Config.set(:origin_country => 'US')
Spree::ActiveShipping::Config.set(:origin_city => 'Atlanta')
Spree::ActiveShipping::Config.set(:origin_state => 'GA')
Spree::ActiveShipping::Config.set(:origin_zip => '30354')
Spree::ActiveShipping::Config.set(:ups_login => 'naturalwellbeing')
Spree::ActiveShipping::Config.set(:ups_password => 'th33mp1r3')
Spree::ActiveShipping::Config.set(:ups_key => 'ABA12A047F52CA84')

#auto capture payments
Spree::Config.set(:auto_capture => true)

#reasons to hold order as suspicious
Spree::Config.set(:hold_order_amount_over => 100.00)
Spree::Config.set(:hold_order_ship_countries => "USA,CAN" )
Spree::Config.set(:hold_order_with_avs =>  "N,W,B" )

Spree::Config.set(:qualified_address_key => 68161790)

Spree::Config.set(:checkout_zone => "All Shipping Zones")

Spree::Config.set(:nwb_free_shipping_at => 75.00)
Spree::Config.set(:pwb_free_shipping_at => 50.00)

Spree::Config.set(:allow_openid => false)

#skip local confirm for PPX
Spree::Config.set(:paypal_express_review => false)

#don't show site name in browser title
Spree::Config.set(:always_put_site_name_in_title => false)

#we don't want to track stock in Spree
Spree::Config.set(:track_inventory_levels => false)


Spree::Config.set(:pwb_fetch_back_code => 2285)
Spree::Config.set(:nwb_fetch_back_code => 2521)