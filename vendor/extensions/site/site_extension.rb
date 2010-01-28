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
    fsm.event :pay do
      transition :to => 'paid', :if => :allow_pay?
      transition :to => 'on_hold', :if => :suspicious_order?
    end

    fsm.event :hold do
      transition :to => 'on_hold', :from => 'paid'
    end

    fsm.event :approve do
      transition :to => 'paid', :from => 'on_hold'
    end

    fsm.after_transition :to => 'on_hold', :do => :make_shipments_pending
    fsm.after_transition :to => 'on_hold', :do => :record_on_hold_reason
    fsm.after_transition :to => 'approved', :do => :make_shipments_ready

    Order.class_eval do
      include ActionView::Helpers::NumberHelper
      belongs_to :store

      def allow_pay?
        return false if suspicious_order?
        checkout_complete
      end

      private
      def restore_state
        # pop the resume / approve event so we can see what the event before that was
        state_events.pop if ["resume", "approve"].include? state_events.last.name
        update_attribute("state", state_events.last.previous_state)
      end

      def suspicious_order?
        state_events.reload

        upper_amount = Spree::Config[:hold_order_amount_over].to_f

        #automatically hold orders
        if !state_events.map(&:name).include?("approve")
          avs = Spree::Config[:hold_order_with_avs].split(",").each(&:strip!)
          countries = Spree::Config[:hold_order_ship_countries].split(",").each(&:strip!)

          if total >= upper_amount
            return true
          elsif bill_address != ship_address
            return true
          elsif !countries.include?(ship_address.country.iso3)
            return true
          elsif payments.any? {|payment| payment.txns.any? { |txn| !avs.include?(txn.avs_response) } }
            return true
          end
        end

        return false
      end

      def record_on_hold_reason
        admin = User.first(:include => :roles, :conditions => ["roles.name = 'admin'"])
        upper_amount = Spree::Config[:hold_order_amount_over].to_f
        avs = Spree::Config[:hold_order_with_avs].split(",").each(&:strip!)
        countries = Spree::Config[:hold_order_ship_countries].split(",").each(&:strip!)

        if total >= upper_amount
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because amount exceeds #{number_to_currency(upper_amount)}.", :user => admin)

        elsif bill_address != ship_address
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because billing and shipping addresses are different.", :user => admin)

        elsif !countries.include?(ship_address.country.iso3)
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because shipping country is not white listed.", :user => admin)

        elsif payments.any? {|payment| payment.txns.any? { |txn| !avs.include?(txn.avs_response) } }
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because AVS code is not white listed.", :user => admin)

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

      def calculate_shipping
        load_object
        if params.key? :zipcode
          addr = Address.new(:zipcode => params[:zipcode], :country_id => 214, :state_name => "")
        else
          addr = Address.new(:zipcode => "", :country_id => params[:country_id], :state_name => "")
        end
        addr.save(false)
        @order.ship_address = addr

        rates =  ShippingMethod.all_available(@order).collect do |ship_method|
          { :id => ship_method.id,
            :name => ship_method.name,
            :rate => ship_method.calculate_cost(@order.checkout.shipment) }
        end

        render :json => rates.to_json
      end

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

      validation_group :delivery, :fields => ["creditcard.number", "creditcard.verification_value"]
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
      layout 'checkouts'

      delivery.edit_hook << :load_available_integrations

      update.before :correct_state_values

      before_filter :set_shipping_method, :only => [:paypal_payment]

      private
      def get_exact_target_lists
        @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
        @exact_target_lists = ExactTargetList.find(:all, :conditions => {:visible => true, :store_id => @site.id})
      end

      #Resets state ABBR values for QualifiedAddress changed states.
      def correct_state_values
        return unless params.has_key? :checkout
        if params[:checkout].has_key?(:bill_address_attributes) && params[:checkout][:bill_address_attributes].has_key?(:state_id)
          if params[:checkout][:bill_address_attributes][:state_id].size == 2
            params[:checkout][:bill_address_attributes][:state_id] = State.find_by_abbr_and_country_id(params[:checkout][:bill_address_attributes][:state_id], params[:checkout][:bill_address_attributes][:country_id]).id
          end
        end

        if params[:checkout].has_key?(:ship_address_attributes) && params[:checkout][:ship_address_attributes].has_key?(:state_id)
          if params[:checkout][:ship_address_attributes][:state_id].size == 2
            params[:checkout][:ship_address_attributes][:state_id] = State.find_by_abbr_and_country_id(params[:checkout][:ship_address_attributes][:state_id], params[:checkout][:ship_address_attributes][:country_id]).id
          end
        end
      end

      #sorting by (and selecting) cheapest shipping method
      def load_available_methods
        @available_methods = rate_hash.sort_by{ |sm| sm[:rate] }
        @checkout.shipping_method_id ||= @available_methods.first[:id]
      end

      # sets shipping medthod for checkout when using paypal payment option
      def set_shipping_method
        load_object
        @checkout.update_attribute(:shipping_method_id, params[:shipping_method])
        @checkout.order.update_totals!
      end

    end

    Spree::ExactTarget.module_eval do
      def autosubscribe_list(store)
        ExactTargetList.find(:first, :conditions => ["store_id = ? AND subscribe_all_new_users = ?", store.id, true])
      end

      def create_subscriber(user)
        if user.is_a? String
          checkout = Checkout.find_by_email user

          list = autosubscribe_list(checkout.order.store) if checkout
        else
          list = autosubscribe_list(user.store)
        end


        if list.nil?
          subscriber_id = -1
        else
          subscriber = ET::Subscriber.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

          begin
            if user.is_a? String
              subscriber_id = subscriber.add(user, list.list_id)
            else
              subscriber_id = subscriber.add(user.email, list.list_id, {:Customer_ID => user.id, :Customer_ID_NWB => user.id, :Customer_ID_PWB => user.id})
            end
            user.exact_target_lists << list
            user.save!
          rescue
            subscriber_id = -1
          end
        end

        unless user.is_a? String
          user.exact_target_subscriber_id = subscriber_id
          user.save!
        end
      end
    end

    SiteShipmentObserver.instance

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

    ETUserObserver.class_eval do

      def after_create(user)
        create_subscriber(user)

        #send account info email
        trigger = ET::TriggeredSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

        external_key = (user.store.code == "nwb" ? "nwb-accountinfo" : "pwb-accountInfo")
        result = trigger.deliver(user.email, external_key, {:First_Name => "Customer", :emailaddr => user.email})
      end
    end

    ETOrderObserver.class_eval do

      def after_hold(order, transition)
        avs = Spree::Config[:hold_order_with_avs].split(",").each(&:strip!)

        if order.payments.any? {|payment| payment.txns.any? { |txn| !avs.include?(txn.avs_response) } }
          trigger = ET::TriggeredSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

          external_key = (order.store.code == "nwb" ? "nwb-ordersecurity" : "pwb-custordersecurity")
          result = trigger.deliver(order.checkout.email, external_key, { :First_Name => order.bill_address.firstname,
                                                                         :Last_name => order.bill_address.lastname})
        end
      end

      def after_ship(order, transition)
        trigger = ET::TriggeredSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

        external_key = (order.store.code == "nwb" ? "nwb-ordershipped" : "pwb-custordershipped ")
        result = trigger.deliver(order.checkout.email, external_key, { :First_Name => order.bill_address.firstname,
                                                                       :Last_name => order.bill_address.lastname,
                                                                       :SENDTIME_CONTENT2 => "Your order has been shipped"})
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
      after_filter :assign_to_store, :only => [:create, :update]

      private
      def initialize_order_events
        @order_events = %w{cancel hold approve resume}
      end

      def assign_to_store
        @order.update_attribute(:store_id, Store.find_by_code("nwb").id) if @order.store.nil?
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

    #hide dashboard for admin area.
    Admin::OverviewController.class_eval do
      private
      def show_dashboard
        false
      end
    end

    Calculator::FlatOverValue.register

    #Need to redirect to delivery step on failure (not the default payment)
    Spree::PaypalExpress.module_eval do
      def paypal_payment
        load_object
        opts = all_opts(@order, 'payment')
        opts.merge!(address_options(@order))
        gateway = paypal_gateway

        response = gateway.setup_authorization(opts[:money], opts)
        unless response.success?
          gateway_error(response)
          redirect_to edit_order_checkout_url(@order, :step => "delivery")
          return
        end

        redirect_to (gateway.redirect_url_for response.token)
      end
    end
 end

end
