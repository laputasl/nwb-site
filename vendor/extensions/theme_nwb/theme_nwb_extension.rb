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


    Admin::ReportsController.class_eval do
      def sales_total
        @taxonomy = Taxonomy.first
        params[:search] = {} unless params[:search]

        if params[:search][:created_at_after].blank?
          params[:search][:created_at_after] = Time.zone.now.beginning_of_month
        else
          params[:search][:created_at_after] = Time.zone.parse(params[:search][:created_at_after]).beginning_of_day rescue Time.zone.now.beginning_of_month
        end

        if params[:search][:created_at_before].blank?
          params[:search][:created_at_before] = Time.zone.now
        else
          params[:search][:created_at_before] = Time.zone.parse(params[:search][:created_at_before]).end_of_day rescue ""
        end

        @search = Order.searchlogic(params[:search])
        
        if params[:category_id].present? && @taxon = Taxon.find(params[:category_id])
          @search = @search.line_items_variant_product_in_taxon(@taxon)
        end
        if params[:image_number].present?
          @search = @search.line_items_variant_sku_eq(params[:image_number])
        end
        #set order by to default or form result
        @search.order ||= "descend_by_created_at"
        @orders = @search.find(:all).uniq
        
        @item_total = @orders.inject(0){|acc, o| acc + o.item_total}
        @charge_total = @orders.inject(0){|acc, o| acc + o.adjustment_total}
        @credit_total = @orders.inject(0){|acc, o| acc + o.credit_total}
        @sales_total = @orders.inject(0){|acc, o| acc + o.total}
      end
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
        
        define_method "#{style}_image_url" do |product|
          if product.images.empty?
            url_for( {:controller=> "/#{@current_domain}/images/noimage/#{style}.jpg", :path_only =>false} )
          else
            image = product.images.first
            if request.ssl?
              image.attachment.url(style).gsub("http://", "https://")
            else
              image.attachment.url(style)
            end
          end
        end
        
        
      end

    end
  end
end
