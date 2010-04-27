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

      [:mini, :small, :product, :large].each do |style|
        define_method "#{style}_image" do |product, *options|
          options = options.first || {}
          if product.images.empty?
            options.reverse_merge! :alt => product.name
            image_tag "/#{@current_domain}/images/noimage/#{style}.jpg", options
          else
            image = product.images.first
            options.reverse_merge! :alt => image.alt.blank? ? product.name : image.alt

            if request.ssl?
              image_tag image.attachment.url(style).gsub("http://", "https://"), options
            else
              image_tag image.attachment.url(style), options
            end

          end
        end
      end

    end
  end
end
