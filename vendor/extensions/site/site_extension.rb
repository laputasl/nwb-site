# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class SiteExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/site"

  def self.require_gems(config)
    config.gem 'right_aws'
  end

  def activate
    Image.attachment_definitions[:attachment][:storage] = :s3
    Image.attachment_definitions[:attachment][:s3_credentials] = "#{RAILS_ROOT}/config/s3.yml"
    Image.attachment_definitions[:attachment][:bucket] = "nwb"
    Image.attachment_definitions[:attachment][:path] = ":attachment/:id/:style.:extension"
    Image.attachment_definitions[:attachment].delete :url

    Spree::BaseController.class_eval do
      before_filter :set_layout

      private
      def set_layout
        @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
        @backto_site = request.headers['wellbeing-backto']
        self.class.layout @site.code
      end
    end

    Admin::BaseController.class_eval do
      before_filter :add_additional_fields

      private
      def add_additional_fields
        # @product_admin_tabs << {:name => "Additional Fields", :url => "additional_fields_admin_product_url"}
      end
    end

    Admin::ProductsController.class_eval do
      def additional_fields
        load_object
        @countries = Country.find(:all).sort
      end
    end

    Spree::BaseController.class_eval do
      def get_taxonomies
        @taxonomies ||= Taxonomy.find(:all, :include => {:root => :children}, :conditions => ["store_id = ?", @site.id])
        @taxonomies
      end
    end

    ProductsHelper.module_eval do
      def seo_url(taxon, product = nil)
        return "#{ActionController::Base.relative_url_root}/t/" + taxon.permalink if product.nil?
      end
    end

    Variant.additional_fields += [ {:name => 'Store Id', :only => [:product], :use => 'select', :value => lambda { |controller, field| Store.all.collect {|s| [s.name, s.id ]}  } } ]

    Product.class_eval do
      belongs_to :store
    end

    Taxonomy.class_eval do
      belongs_to :store
    end

    Order.class_eval do
      belongs_to :store
    end

    OrdersController.class_eval do
      create.before << :assign_to_store

      private
      def assign_to_store
        @order.store = @site
      end

    end
  end

end
