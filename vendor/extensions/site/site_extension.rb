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
      prepend_before_filter :set_layout
      before_filter :load_global_taxons
      helper :products, :taxons

      private
      def set_layout
        @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
        @current_domain = request.headers['wellbeing-domain']
        self.class.layout @current_domain
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
      before_filter :can_show_product, :only => :show

      show.wants.html { render :partial => "#{@current_domain}_show", :layout => true }

      private
      def can_show_product
       if (@product.store.nil? || (@product.store.code != @site.code)) || (RAILS_ENV == "production" && params[:id].is_integer?)
         render :file => "public/404.html", :status => 404
       end
      end
    end

    Variant.additional_fields += [ {:name => 'Store Id', :only => [:product], :use => 'select', :value => lambda { |controller, field| Store.all.collect {|s| [s.name, s.id ]}  } } ]

    Product.class_eval do
      belongs_to :store

      named_scope :by_store, lambda { |*args| { :conditions => ["products.store_id = ?", args.first] } }

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

    ExactTargetList.class_eval do
      belongs_to :store
    end

    OrdersController.class_eval do
      create.before << :assign_to_store

      private
      def assign_to_store
        @order.store = @site
      end

    end

    Spree::Search.module_eval do
      def retrieve_products
        # taxon might be already set if this method is called from TaxonsController#show
        @taxon ||= Taxon.find_by_id(params[:taxon]) unless params[:taxon].blank?
        # add taxon id to params for searcher
        params[:taxon] = @taxon.id if @taxon
        @keywords = params[:keywords]
        per_page = params[:per_page] || Spree::Config[:products_per_page]
        params[:per_page] = per_page
        curr_page = Spree::Config.searcher.manage_pagination ? 1 : params[:page]
        # Prepare a search within the parameters
        Spree::Config.searcher.prepare(params)

        if params[:product_group_name]
          @product_group = ProductGroup.find_by_permalink(params[:product_group_name])
        elsif params[:product_group_query]
          @product_group = ProductGroup.new.from_route(params[:product_group_query])
        else
          @product_group = ProductGroup.new
        end

        #SITE SPECIFIC: only retrieve products for the current store.
        @product_group.add_scope('by_store', @site.id)

        @product_group.add_scope('in_taxon', @taxon) unless @taxon.blank?
        @product_group.add_scope('keywords', @keywords) unless @keywords.blank?
        @product_group = @product_group.from_search(params[:search]) if params[:search]

        params[:search] = @product_group.scopes_to_hash if @keywords.blank?

        base_scope = Spree::Config[:allow_backorders] ? Product.active : Product.active.on_hand
        @products_scope = @product_group.apply_on(base_scope)

        @products = @products_scope.paginate({
            :include  => [:images, :master],
            :per_page => per_page,
            :page     => curr_page
          })
        @products_count = @products_scope.count

        return(@products)
      end
    end

    UsersController.class_eval do
      private
      def get_exact_target_lists
        @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
        @exact_target_lists = ExactTargetList.find(:all, :conditions => {:visible => true, :store_id => @site.id})
      end
    end

    Spree::ExactTarget.module_eval do
      def autosubscribe_list
        ExactTargetList.find(:first, :conditions => ["store_id = ? AND subscribe_all_new_users = ?", @site.id, true])
      end
    end

    ExactTargetList.class_eval do
      def validate
        if self.new_record?
          errors.add_to_base I18n.translate("exact_target.only_list_can_subscribe_all") if self.subscribe_all_new_users && ExactTargetList.exists?(["subscribe_all_new_users = ? AND store_id = ?" , true, self.store_id])
        else
          errors.add_to_base I18n.translate("exact_target.only_list_can_subscribe_all") if self.subscribe_all_new_users && ExactTargetList.exists?(["subscribe_all_new_users = ? AND id <> ? AND store_id = ?" , true, self.id, self.store_id])
        end
      end
    end

  end

end
