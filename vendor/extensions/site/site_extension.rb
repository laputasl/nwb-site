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

    base = File.dirname(__FILE__)
    Dir.glob(File.join(base, "app/**/*_decorator*.rb")) do |c|
      RAILS_ENV=="production" ? require(c) : load(c)
    end

    Spree::BaseController.class_eval do
      before_filter :set_layout, :load_global_taxons
      helper :products

      private
      def set_layout
        @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
        @backto_site = request.headers['wellbeing-backto']
        self.class.layout @site.code
      end

      def get_taxonomies
        @taxonomies ||= Taxonomy.find(:all, :include => {:root => :children}, :conditions => ["store_id = ?", @site.id])
        @taxonomies
      end

      def load_global_taxons
        @categories = Taxonomy.find(:first, :conditions => {:store_id => @site.id, :name => "Category"})
      end
    end

    Admin::ProductsController.class_eval do
      def additional_fields
        load_object
        @countries = Country.find(:all).sort
      end
    end

    ProductsController.class_eval do
      show.wants.html { render :partial => "#{@site.code}_show", :layout => true }
    end

    Variant.additional_fields += [ {:name => 'Store Id', :only => [:product], :use => 'select', :value => lambda { |controller, field| Store.all.collect {|s| [s.name, s.id ]}  } } ]

    Product.class_eval do
      belongs_to :store

      private
      def validate
        errors.add(:can_be_part, "cannot be true when the product contains parts.") if assembly? && can_be_part
      end
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
