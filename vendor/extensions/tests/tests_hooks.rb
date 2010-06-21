class TestsHooks < Spree::ThemeSupport::HookListener

  #
  # In this file you can modify the content of the hooks available in the default templates
  # and avoid overriding a template in many situations. Multiple extensions can modify the
  # same hook, the changes being applied cumulatively based on extension load order
  #
  # Most hooks are defined with blocks so they span a region of the template, allowing content
  # to be replaced or removed as well as added to.
  #
  # Usage
  #
  # The following methods are available
  #
  # * insert_before
  # * insert_after
  # * replace
  # * remove
  #
  # All accept a block name symbol followed either by arguments that would be valid for 'render'
  # or a block which returns the string to be inserted. The block will have access to any methods
  # or instance variables accessible in your views
  #
  # Examples
  # 
  #   insert_before :homepage_products, :text => "<h1>Welcome!</h1>"
  #   insert_after :homepage_products, 'shared/offers' # renders a partial
  #   replace :taxon_sidebar_navigation, 'shared/my_sidebar
  #
  # adding a link below product details:
  #
  #   insert_after :product_description do
  #    '<p>' + link_to('Back to products', products_path) + '</p>'
  #   end
  #
  # adding a new tab to the admin navigation
  #
  
=begin
  def enable(id)
    @gwo_test=GwoTest.find(id)

    if(@gwo_test.category == 'MV')

      replace :nwb_control do
        "<%= render :partial => 'shared/gwo/nwb_control', :locals => {:id => '"+@gwo_test.eid+"'}%>"      
      end
      replace :nwb_tracking do
        "<%= render :partial => 'shared/gwo/nwb_tracking', :locals => {:id => '"+@gwo_test.eid+"', :ga_pid => '"+@gwo_test.pid+"'} %>"
      end
      replace :nwb_conversion do
        "<%= render :partial => 'shared/gwo/nwb_conversion', :locals => {:id => '"+@gwo_test.eid+"', :ga_pid => '"+@gwo_test.pid+"'} %>"
      end
      replace :pre_body_opening_tag do
        "<script>utmx_section('body_tag')</script>"
      end
      replace :post_body_opening_tag do
        "</noscript>"
      end

    end

    @gwo_test.update_attribute(:status, "enabled")
  end

  def disable(id)
  end
  
  @gwo_tests=GwoTest.find(:all)
  @gwo_tests.each do|gwo_test|
    if(gwo_test.status=="enabled")
      enable(gwo_test.id)
    else
      disable(gwo_test.id)
    end
  end
=end
  
     insert_after :admin_tabs do
       %(<%=  tab(:gwo_tests)  %>)
     end
  #

end
