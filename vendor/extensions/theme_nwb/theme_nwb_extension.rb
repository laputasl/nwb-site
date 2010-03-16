# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ThemeNwbExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/theme_nwb_extension"

  # Please use theme_nwb_extension/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end
  
  def activate
    # make your helper avaliable in all views
    Spree::BaseController.class_eval do
      helper NwbThemeHelper
    end
    
    Spree::BaseHelper.module_eval do

      def global_categories
        current_site = Store.find_by_code(request.headers['wellbeing-domain'])
        Taxonomy.find(:first, :conditions => {:store_id => current_site.id, :name => "Category"})
      end


      def mini_image(product, options={})
        if product.images.empty?
          image_tag "/#{@site.code}/images/noimage/mini.png", options
        else
          image_tag product.images.first.attachment.url(:mini), options
        end
      end

      def small_image(product, options={})
        if product.images.empty?
          image_tag "/#{@site.code}/images/noimage/small.png", options
        else
          image_tag product.images.first.attachment.url(:small), options
        end
      end

      def product_image(product, options={})
        if product.images.empty?
          image_tag "/#{@site.code}/images/noimage/product.png", options
        else
          image_tag product.images.first.attachment.url(:product), options
        end
      end
      
    end
  end
end
