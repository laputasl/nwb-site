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

    Spree::BaseController.send(:include, Spree::BaseControllerOverrides)

    Admin::ProductsController.class_eval do
      def additional_fields
        load_object
        @countries = Country.find(:all).sort
      end
    end

    ProductsController.class_eval do
      before_filter :can_show_product, :only => :show

      private
      def can_show_product
       if (@product.store.nil? || (@product.store.code != @site.code)) || (RAILS_ENV == "production" && params[:id].is_integer?)
         render :file => "public/404.html", :status => 404
       end

       #load taxon if not set (where referrer fails)
       @taxon ||= (@product.taxons & @categories.taxons).first
      end

    end

    Variant.additional_fields += [ {:name => 'Store Id', :only => [:product], :use => 'select', :value => lambda { |controller, field| Store.all.collect {|s| [s.name, s.id ]}  } } ]

    Product.class_eval do
      belongs_to :store

      named_scope :by_store, lambda { |*args| { :conditions => ["products.store_id = ?", args.first] } }

      xapit do |index|
        index.text :name, :description, :subtitle_main, :sales_copy, :short_home, :ingredients
        index.field :is_active, :taxon_ids
        index.facet :gender_property, "Gender"
        index.facet :brand_property, "Brand"
        index.facet :price_range, "Price"
        index.facet :taxon_names, "Taxon"
        index.sortable :price
      end

      private
      def validate
        errors.add(:can_be_part, "cannot be true when the product contains parts.") if assembly? && can_be_part
      end
    end

    Taxonomy.class_eval do
      belongs_to :store
    end

    fsm = Order.state_machines[:state]
    fsm.event :hold do
      transition :to => 'held', :from => ['paid', 'new']
    end

    fsm.event :approve do
      transition :to => 'approved', :from => 'held', :if => :allow_resume?
    end

    fsm.after_transition :to => 'approved', :do => :restore_state
    fsm.after_transition :to => 'paid', :do => :monitor_suspicious_orders

    Order.class_eval do
      include ActionView::Helpers::NumberHelper
      belongs_to :store

      private
      def restore_state
        # pop the resume / approve event so we can see what the event before that was
        state_events.pop if ["resume", "approve"].include? state_events.last.name
        update_attribute("state", state_events.last.previous_state)
      end

      def monitor_suspicious_orders
        state_events.reload

        upper_amount = Spree::Config[:hold_order_amount_over].to_f

        #automatically hold orders
        if can_hold? && !state_events.map(&:name).include?("approve")
          admin = User.first(:include => :roles, :conditions => ["roles.name = 'admin'"])

          avs = Spree::Config[:hold_order_with_avs].split(",").each(&:strip!)
          countries = Spree::Config[:hold_order_ship_countries].split(",").each(&:strip!)

          if total >= upper_amount
            hold!
            self.comments.create(:title => "Order Held", :comment => "Held as suspicious because amount exceeds #{number_to_currency(upper_amount)}.", :user => admin)
          elsif bill_address != ship_address
            hold!
            self.comments.create(:title => "Order Held", :comment => "Held as suspicious because billing and shipping addresses are different.", :user => admin)
          elsif !countries.include?(ship_address.country.iso3)
            hold!
            self.comments.create(:title => "Order Held", :comment => "Held as suspicious because shipping country is not white listed.", :user => admin)
          elsif payments.any? {|payment| payment.txns.any? { |txn| !avs.include?(txn.avs_response) } }
            hold!
            self.comments.create(:title => "Order Held", :comment => "Held as suspicious because AVS code is not white listed.", :user => admin)
          end
        end
      end
    end

    InventoryUnit.class_eval do
      InventoryUnit.state_machines[:state] = StateMachine::Machine.new(InventoryUnit, :initial => 'on_hand') do
        event :fill_backorder do
          transition :to => 'sold', :from => 'backordered'
        end
        event :ship do
          transition :to => 'shipped', :if => :allow_ship? #, :from => 'sold'
        end
        event :backorder do
          transition :to => 'backordered', :from => 'sold'
        end
      end
    end

    Shipment.class_eval do
      def editable_by?(user)
        %w(pending ready_to_ship unable_to_ship needs_fulfilment).include?(state) or user.has_role?(:admin)
      end

      Shipment.state_machines[:state] = StateMachine::Machine.new(Shipment, :initial => 'pending') do
        event :ready do
          transition :from => 'pending', :to => 'ready_to_ship'
        end
        event :pend do
          transition :from => 'ready_to_ship', :to => 'pending'
        end
        event :ship do
          transition :from => ['needs_fulfilment', 'acknowledged'], :to => 'shipped'
        end
        event :transmit do
          transition :from => 'ready_to_ship', :to => 'transmitted'
        end
        event :acknowledge do
          transition :from => 'transmitted', :to => 'acknowledged'
        end
        event :flag do
          transition :from => 'ready_to_ship', :to => 'needs_fulfilment'
        end
        event :problem do
          transition :from => ['transmitted', 'acknowledged', 'needs_fulfilment'], :to => 'unable_to_ship'
        end
        after_transition :to => 'shipped', :do => :transition_order
      end
    end

    OrdersController.class_eval do
      create.before << :assign_to_store

      private
      def assign_to_store
        @order.store = @site
      end

    end
        

    Checkout.class_eval do
      Checkout.state_machines[:state] = StateMachine::Machine.new(Checkout, :initial => 'address') do
        after_transition :to => 'complete', :do => :complete_order
        before_transition :to => 'complete', :do => :process_payment
        event :next do
          transition :to => 'delivery', :from  => 'address'
          transition :to => 'confirm', :from => 'delivery'
          transition :to => 'complete', :from => 'confirm'
        end
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

    CheckoutsController.class_eval do
      # register edit and update hooks for extra checkout steps
      class_scoping_reader :confirm, Spree::Checkout::ActionOptions.new
      
      private
      def get_exact_target_lists
        @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
        @exact_target_lists = ExactTargetList.find(:all, :conditions => {:visible => true, :store_id => @site.id})
      end
    end

    Spree::ExactTarget.module_eval do
      def autosubscribe_list(store)
        ExactTargetList.find(:first, :conditions => ["store_id = ? AND subscribe_all_new_users = ?", store.id, true])
      end

      def create_subscriber(user)
        list = autosubscribe_list(user.store)

        if list.nil?
          subscriber_id = -1
        else
          subscriber = ET::Subscriber.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

          begin
            subscriber_id = subscriber.add(user.email, list.list_id, {:Customer_ID => user.id, :Customer_ID_NWB => user.id, :Customer_ID_PWB => user.id})
            user.exact_target_lists << list
            user.save!
          rescue
            subscriber_id = -1
          end
        end

        user.exact_target_subscriber_id = subscriber_id
        user.save!
      end
    end

    ExactTargetList.class_eval do
      belongs_to :store

      def validate
        if self.new_record?
          errors.add_to_base I18n.translate("exact_target.only_list_can_subscribe_all") if self.subscribe_all_new_users && ExactTargetList.exists?(["subscribe_all_new_users = ? AND store_id = ?" , true, self.store_id])
        else
          errors.add_to_base I18n.translate("exact_target.only_list_can_subscribe_all") if self.subscribe_all_new_users && ExactTargetList.exists?(["subscribe_all_new_users = ? AND id <> ? AND store_id = ?" , true, self.id, self.store_id])
        end
      end
    end

    User.class_eval do
      belongs_to :store

      attr_accessible :store_id
    end

    UserMailer.class_eval do
      def password_reset_instructions(user)
        subject       Spree::Config[:site_name] + ' ' + I18n.t("password_reset_instructions")
        from          Spree::Config[:mails_from]
        recipients    user.email
        sent_on       Time.now
        body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token), :user => user
      end
    end

    Admin::OrdersController.class_eval do
      private
      def initialize_order_events
        @order_events = %w{cancel hold approve resume}
      end
    end

    ShippingMethod.class_eval do
      def available_to_address?(address)
        po_regex = /\b((A|a|F|f)?[P|p](OST|ost)?\.?\s?[O|o|0](ffice|FFICE)?\.?\s)?([B|b][O|o|0][X|x])\s(\d+)/

        if self.name.upcase.include?("UPS") && (address.address1 =~ po_regex || address.address2 =~ po_regex)
          return false
        else
          available? && zone.include?(address)
        end
      end
    end

    Address.class_eval do
      def ==(other_address)
        self_attrs = self.attributes
        other_attrs = other_address.respond_to?(:attributes) ? other_address.attributes : {}
        [self_attrs, other_attrs].each do |attrs|
          %w(id created_at updated_at order_id).each {|attr| attrs.delete(attr) }
        end

        self_attrs == other_attrs
      end
    end
 end

end
