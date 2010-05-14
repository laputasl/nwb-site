# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class SiteExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/site"

  NWB_HTTP_REFERER_REGEX = /^https?:\/\/[^\/]+\/(c\/[a-z0-9\-\/]*)$/

  def self.require_gems(config)
    # store switcher needs to load first
    config.metals = ["StoreSwitcher", "LegacyRedirect"]

    #config.gem 'right_aws'
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
      #prevents pwb products from appearing on nwb (and vice versa)
      def can_show_product
        if RAILS_ENV == "production" && params[:id].is_integer?
          render :file => "public/404.html", :status => 404
        elsif (@product.store.nil? || (@product.store.code != @site.code))

          if ActionController::Base.relative_url_root.blank?
            if @product.store.code == "pwb"
              redirect_to "/pets/products/#{@product.permalink}"
            else
              redirect_to "/people/products/#{@product.permalink}"
            end

          else
            redirect_to "/products/#{@product.permalink}" #not the same as product_url as we want to drop the relative_url_root
          end

        end
      end

      #custom regex above to match SEO short urls (plus need to prepend / below for taxon find)
      def load_data
        #load_object
        @variants = Variant.active.find_all_by_product_id(@product.id,
                    :include => [:option_values, :images])
        @product_properties = ProductProperty.find_all_by_product_id(@product.id,
                              :include => [:property])
        @selected_variant = @variants.detect { |v| v.available? }

        referer = request.env['HTTP_REFERER']
        if referer && referer.match(NWB_HTTP_REFERER_REGEX)
          url = $1
          url += "/" unless url[-1..-1] == "/"
          @taxon = Taxon.find_by_permalink(url)
        elsif !session[:last_taxon_permalink].blank?
          @taxon = @product.taxons.find_by_permalink(session[:last_taxon_permalink])
        end

        #fall back if nothing sets taxon
        @taxon ||= (@product.taxons & @categories.taxons).first

      end

      def accurate_title
        return nil if @product.nil?

        @product.page_title.blank? ?  @product.name : @product.page_title
      end

    end

    Variant.additional_fields += [ {:name => 'Store Id', :only => [:product], :use => 'select', :value => lambda { |controller, field| Store.all.collect {|s| [s.name, s.id ]}  } } ]

    Product.class_eval do
      belongs_to :store

      named_scope :by_store, lambda { |*args| { :conditions => ["products.store_id = ?", args.first] } }

      xapit do |index|
        index.text :name, :weight => 10
        index.text :description, :subtitle_main, :sales_copy, :short_home, :ingredients
        index.text :sku
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

    fsm.event :archive do
      transition :to => 'legacy', :if => false
    end

    fsm.event :reship do
      transition :to => 'paid', :if => :has_problem_shipment?
    end


    fsm.after_transition :to => 'on_hold', :do => :make_shipments_pending
    fsm.after_transition :to => 'on_hold', :do => :record_on_hold_reason
    fsm.after_transition :to => 'paid', :do => :check_for_reship

    Order.class_eval do
      include ActionView::Helpers::NumberHelper
      belongs_to :store
      has_many :reminder_messages, :as => :remindable

      def allow_pay?
        return false if suspicious_order?
        checkout_complete
      end

      def available_shipping_rates(zipcode, country_id)
        return [] if zipcode.nil? && country_id.nil?

        if !zipcode.blank?
          addr = Address.new(:zipcode => zipcode, :country_id => 214, :state_name => "")
        elsif !country_id.blank? && country_id != 0
          addr = Address.new(:zipcode => "", :country_id => country_id, :state_name => "")
        end

        return if addr.nil?
        addr.save(false)
        checkout.update_attribute(:ship_address_id, addr.id)

        rates = shipping_rate_hash
        checkout.enable_validation_group(:register)

        if rates.size > 0 && checkout.shipping_method_id.nil?
          checkout.update_attribute(:shipping_method_id, rates[0][:id])
        end

        self.update_totals! #update totals are method maybe the same, but the rate could have changed.

        rates
      end

      def shipping_rate_hash

        rates = ShippingMethod.all_available(self).collect do |ship_method|
          { :id => ship_method.id,
            :name => ship_method.name,
            :rate => ship_method.calculate_cost(self.checkout.shipment),
            :position => ship_method.position,
            :can_be_free => ship_method.can_be_free }
        end

        rates.reject! { |rate| rate[:rate].to_f <= 0.0 && !rate[:can_be_free] }
        rates
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
          avs = Spree::Config[:hold_order_with_avs].to_s.split(",").each(&:strip!)
          countries = Spree::Config[:hold_order_ship_countries].to_s.split(",").each(&:strip!)

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
        avs = Spree::Config[:hold_order_with_avs].to_s.split(",").each(&:strip!)
        countries = Spree::Config[:hold_order_ship_countries].to_s.split(",").each(&:strip!)

        if total >= upper_amount
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because amount exceeds #{number_to_currency(upper_amount)}.", :user => admin)

        elsif bill_address != ship_address
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because billing and shipping addresses are different.", :user => admin)

        elsif !countries.include?(ship_address.country.iso3)
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because shipping country is not white listed.", :user => admin)

        elsif payments.any? {|payment| payment.txns.any? { |txn| !avs.include?(txn.avs_response) } }
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because AVS code (#{txn.avs_response}) is not white listed.", :user => admin)

        end

      end

      def has_problem_shipment?
        shipments.reload.last.state == "unable_to_ship" && inventory_units.any? {|unit| unit.state == "backordered"}
      end

      def check_for_reship(transition)
        if transition.event == :reship
          problem_shipment = shipment
          new_shipment = shipments.new(:shipping_method_id => problem_shipment.shipping_method_id, :address_id => problem_shipment.address_id, :shipping_charge => problem_shipment.shipping_charge)
          new_shipment.inventory_units = problem_shipment.inventory_units.find_all { |unit| unit.state == "backordered" }

          new_shipment.inventory_units.each {|unit| unit.state="sold"}
          new_shipment.save!
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
      after_create :check_order_state
      before_save :generate_shipment_number

      def editable_by?(user)
        %w(pending ready_to_ship unable_to_ship needs_fulfilment).include?(state) or user.has_role?(:admin)
      end

      Shipment.state_machines[:state] = StateMachine::Machine.new(Shipment, :initial => 'pending') do
        event :ready do
          transition :from => 'pending', :to => 'ready_to_ship', :if => :is_ready?
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
          transition :from => ['transmitted', 'acknowledged', 'needs_fulfilment', 'ready_to_ship'], :to => 'unable_to_ship'
        end
        after_transition :to => 'shipped', :do => :transition_order
      end

      #use custom store specific shipment number
      def generate_shipment_number(force=false)
        return self.number unless self.number.blank? || force
        store = order.store.nil? ? Store.last : order.store

        record = true
         while record
          random = "#{store.code == "nwb" ? "1" : "2"}_#{Array.new(11){rand(9)}.join}"
          record = Shipment.find(:first, :conditions => ["number = ?", random])
        end
        self.number = random
      end

      private
      def check_order_state
        self.ready! if (order.paid? && !inventory_units.any? {|unit| unit.backordered? })
      end

      def is_ready?
        order.paid? && !inventory_units.any? {|unit| unit.backordered? }
      end
    end

    OrdersController.class_eval do
      before_filter :set_analytics
      create.before << :assign_to_store
      update.before :check_for_removed_items
      update.after :recalculate_totals

      ssl_allowed :update

      def index
        render :text => "File not found", :status => 404
      end

      update do
        flash nil
        success.wants.html { redirect_to(@from_checkout ? edit_order_checkout_url(object, :step => "delivery")  : edit_order_url(object)) }
        failure.wants.html { render :template => "orders/edit" }
      end

      def new
        @order = find_order
        @order.save
        session[:order_id]    = @order.id
        session[:order_token] = @order.token
        redirect_to edit_order_url(@order)
      end

      def calculate_shipping
        load_object

        if params.key? :zipcode
          session[:zipcode] = params[:zipcode].to_i
          session[:country_id] = nil
        else
          session[:country_id] = params[:country_id].to_i
          session[:zipcode] = nil
        end

        begin
          rates = @order.available_shipping_rates(session[:zipcode], session[:country_id])

          if rates.empty?
            session[:shipping_method_id] = nil
            session[:shipping_method_rate] = nil
          else
            session[:shipping_method_id] = @order.checkout.shipping_method_id
            session[:shipping_method_rate] = @order.shipping_charges.first.amount
          end
        rescue Spree::ShippingError => ship_error
          flash[:error] = ship_error.to_s
          session[:shipping_method_id] = nil
          session[:shipping_method_rate] = nil
          rates = []
        end

        render :json => rates.to_json
      end

      private
      def assign_to_store
        @order.shipment.order.store = @order.store = @site
        @order.shipment.generate_shipment_number(true)
      end

      def set_analytics
        if @current_action == "show"
          if params.key? :checkout_complete
            @analytics_page = "/checkout/receipt"
          else
            @analytics_page = "/account/order-details"
          end
        else
          @analytics_page = "/checkout/basket"
        end
      end

      def check_for_removed_items
        @from_checkout = params.key? "from_checkout"

        return unless params.key? "remove"

        params[:remove].each do |line_item, value|
          LineItem.destroy line_item.to_i
        end

      end

      def recalculate_totals
        @order.update_totals!
        @order.reload
      end
    end

    Checkout.class_eval do
      Checkout.state_machines[:state] = StateMachine::Machine.new(Checkout, :initial => 'address') do
        after_transition :to => 'complete', :do => :complete_order
        before_transition :to => 'complete', :do => :process_payment
        event :next do
          transition :to => 'delivery', :from  => 'address'
          transition :to => 'complete', :from => 'delivery'
        end
      end

      #need to reverse this (ie. bill_address is a copy of ship_address)
      def clone_billing_address
        if self.ship_address.nil?
          self.ship_address = bill_address.clone
        else
          if bill_address.nil?
            self.bill_address = ship_address.clone
          else
            self.bill_address.attributes = ship_address.attributes.except("id", "updated_at", "created_at")
          end
        end
        true
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

        per_page = params[:per_page].to_i
        per_page = per_page > 0 ? per_page : Spree::Config[:products_per_page]
        params[:per_page] = per_page
        params[:page] = 1 if (params[:page].to_i <= 0)

        # Prepare a search within the parameters
        Spree::Config.searcher.prepare(params)

        if !params[:sort_by].blank?
          @product_group = ProductGroup.new.from_route([params[:sort_by]])
        elsif !params[:order_by_price].blank?
          @product_group = ProductGroup.new.from_route([params[:order_by_price]+"_by_master_price"])
        elsif params[:product_group_name]
          @cached_product_group = ProductGroup.find_by_permalink(params[:product_group_name])
          @product_group = ProductGroup.new
        elsif params[:product_group_query]
          @product_group = ProductGroup.new.from_route(params[:product_group_query])
        else
          @product_group = ProductGroup.new
        end

        #SITE SPECIFIC: only retrieve products for the current store - but not if we're searching
        @product_group.add_scope('by_store', @site.id) if @keywords.blank?

        #Add workaround to disable paging for all products pahe
        per_page = 9999 if @current_controller == "products" && @current_action == "index" && @keywords.blank?

        @product_group.add_scope('taxons_id_eq', @taxon) unless @taxon.blank?
        @product_group.add_scope('keywords', @keywords) unless @keywords.blank?
        @product_group = @product_group.from_search(params[:search]) if params[:search]

        base_scope = @cached_product_group ? @cached_product_group.products.active : Product.active
        base_scope = base_scope.on_hand unless Spree::Config[:show_zero_stock_products]
        base_scope = base_scope.scoped(:include => [:images, {:master => :volume_prices}])

        @products_scope = @product_group.apply_on(base_scope)

        curr_page = Spree::Config.searcher.manage_pagination ? params[:page] : 1

        @products = @products_scope.uniq.paginate({
            :per_page => per_page,
            :page     => curr_page
          })
        @products_count = @products_scope.count
        return(@products)
      end
    end

    UsersController.class_eval do
      before_filter :set_analytics

      def create
        @user = User.new(params[:user])
        @user.store = @site
        @user.save do |result|
          if result
            flash[:notice] = t(:user_created_successfully) unless session[:return_to]
            @user.roles << Role.find_by_name("admin") unless admin_created?
            respond_to do |format|
              format.html { redirect_back_or_default products_url }
              format.js { render :js => true.to_json }
            end
          else
            respond_to do |format|
              format.html { render :action => :new }
              format.js { render :js => @user.errors.to_json }
            end
          end
        end
      end

      private
      def get_exact_target_lists
        @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
        @exact_target_lists = ExactTargetList.find(:all, :conditions => {:visible => true, :store_id => @site.id})
      end

      def set_analytics
        @analytics_page = "/account"
      end
    end

    CheckoutsController.class_eval do
      layout 'checkouts'

      delivery.edit_hook << :load_available_payment_methods
      address.edit_hook << :handle_express_users

      update.before :clear_payments_if_in_payment_state, :correct_state_values

      before_filter :update_shipping_method, :only => [:paypal_payment]
      before_filter :set_analytics
      before_filter :get_exact_target_lists, :only => [:edit]
      before_filter :enforce_registration, :except => [:register, :set_shipping_method]

      ssl_allowed :set_shipping_method

      # sets shipping medthod for checkout when using paypal payment option
      def set_shipping_method
        render :json => update_shipping_method
      end

      def update
        load_object

        # call the edit hooks for the current step in case we experience validation failure and need to edit again
        edit_hooks
        @checkout.enable_validation_group(@checkout.state.to_sym)
        @prev_state = @checkout.state

        before :update

        begin
          if @checkout.update_attributes object_params
            update_hooks

            force_shipping_method

            @checkout.order.update_totals!
            after :update

            next_step unless params[:checkout][:coupon_code] && @checkout.delivery?

            if @checkout.completed_at
              return complete_checkout
            end
            #force reload of order so coupon difference will appear
            @order.reload
          else
            after :update_fails
            set_flash :update_fails
          end
        rescue Spree::GatewayError => ge
          logger.debug("#{ge}:\n#{ge.backtrace.join("\n")}")
          flash.now[:error] =   %(<h4>Your credit card was not charged.</h4>
                                  <p>It looks like there was an issue with the credit card information entered. Please try again... and make sure the information appears just like it does on your credit card.</p>)
        rescue Spree::ShippingError => se #handle bad addresses / errors from ActiveShipping
          logger.debug("#{se}:\n#{se.backtrace.join("\n")}")
          flash.now[:error] = se.message
          @checkout.state = "address"
        end

        render 'edit'
      end

      private

      def load_data #ensures correct states list is created when updating checkout (site specific as nwb uses ship address as primary)
        @countries = Checkout.countries.sort
        if params[:checkout] && params[:checkout][:ship_address_attributes]
          default_country = Country.find params[:checkout][:ship_address_attributes][:country_id]
        elsif object.bill_address && object.bill_address.country
          default_country = object.bill_address.country
        elsif current_user && current_user.bill_address
          default_country = current_user.bill_address.country
        else
          default_country = Country.find Spree::Config[:default_country_id]
        end
        @states = default_country.states.sort

        # prevent editing of a complete checkout
        redirect_to order_url(parent_object) if parent_object.checkout_complete
      end

      def object_params
        # For delivery (normally payment) step, filter checkout parameters to produce the expected nested attributes for a single payment and its source, discarding attributes for payment methods other than the one selected
        if object.delivery? && params[:checkout].key?(:payments_attributes)
          if source_params = params.delete(:payment_source)[params[:checkout][:payments_attributes].first[:payment_method_id].underscore]
            params[:checkout][:payments_attributes].first[:source_attributes] = source_params
          end
          params[:checkout][:payments_attributes].first[:amount] = @order.total
        end
        params[:checkout]
      end

      def clear_payments_if_in_payment_state
        if @checkout.delivery?
          @checkout.payments.clear
        end
      end

      def get_exact_target_lists #make multi-store aware
        @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
        @exact_target_lists = ExactTargetList.find(:all, :conditions => {:visible => true, :store_id => @site.id})
      end

      #Resets state ABBR values for QualifiedAddress changed states.
      def correct_state_values
        return unless params.has_key? :checkout

        if params[:checkout].has_key?(:ship_address_attributes) && params[:checkout][:ship_address_attributes].has_key?(:state_id)
          if params[:checkout][:ship_address_attributes][:state_id].size == 2
            params[:checkout][:ship_address_attributes][:state_id] = State.find_by_abbr_and_country_id(params[:checkout][:ship_address_attributes][:state_id], params[:checkout][:ship_address_attributes][:country_id]).id
          end
        end

        #use_billing actually means use_shipping
        if params[:checkout][:use_billing] == "1"
          params[:checkout].delete :bill_address_attributes #don't need this as we clone (and might be missing values)
        else
          if params[:checkout].has_key?(:bill_address_attributes) && params[:checkout][:bill_address_attributes].has_key?(:state_id)
            if params[:checkout][:bill_address_attributes][:state_id].size == 2
              params[:checkout][:bill_address_attributes][:state_id] = State.find_by_abbr_and_country_id(params[:checkout][:bill_address_attributes][:state_id], params[:checkout][:bill_address_attributes][:country_id]).id
            end
          end
        end

      end

      def next_step
        @checkout.next!
        # call edit hooks for this next step since we're going to just render it (instead of issuing a redirect)
        edit_hooks

        set_analytics
      end

      def set_analytics
        load_object

        if @current_action == "register"
          @analytics_page = "/checkout/register"
        elsif object.state == "address"
          @analytics_page = "/checkout/address"
        elsif object.state == "delivery"
          @analytics_page = "/checkout/payment"
        elsif object.state == "confirm"
          @analytics_page = "/checkout/confirm"
        end

      end

      def update_shipping_method
        load_object
        object.enable_validation_group(:register)

        if @checkout.update_attribute(:shipping_method_id, params[:shipping_method])
          @checkout.order.update_totals!

          session[:shipping_method_id] = params[:shipping_method].to_i
          session[:shipping_method_rate] = @checkout.order.shipping_charges.first.amount

          true
        else
          false
        end
      end

      #returns rates sorted by :position
      def rate_hash
        @checkout.order.shipping_rate_hash
      end

      #allows registered users to skip address step.
      def handle_express_users
        return if params[:step] == "address" || current_user.nil?

        unless @checkout.ship_address.valid?
          @checkout.ship_address.attributes = current_user.ship_address.attributes.except("id", "updated_at", "created_at") if current_user.ship_address
        end

        if @checkout.ship_address.changed?
          @checkout.ship_address.save
          @checkout.order.reload
        end

        force_shipping_method

        #can't skip addressing if the checkout is not valid.
        if @checkout.valid?
          @checkout.enable_validation_group(:address)

          @checkout.next
          load_available_payment_methods
          load_available_methods
        else
          @checkout.errors.clear
        end
      end

      def force_shipping_method
        #set default shippping method if none selected yet (or it's no longer valid)
        available_shipping_methods = @checkout.shipping_methods

        if (@checkout.shipping_method.nil? || !available_shipping_methods.map(&:id).include?(@checkout.shipping_method.id)) && @checkout.ship_address.valid?

          unless available_shipping_methods.empty?
            @checkout.update_attribute(:shipping_method_id, available_shipping_methods[0].id)
            @checkout.reload
            @order = @checkout.order
            @order.update_totals!

            session[:shipping_method_id] = available_shipping_methods[0].id
            session[:shipping_method_rate] = @checkout.order.ship_total
          end
        end
      end
    end

    Spree::ExactTarget.module_eval do
      def autosubscribe_list(store)
        ExactTargetList.find(:first, :conditions => ["store_id = ? AND subscribe_all_new_users = ?", store.id, true])
      end

      def create_subscriber(user)
        if user.is_a? String
          checkout = Checkout.find_by_email(user, :order => "updated_at desc")

          list = autosubscribe_list(checkout.order.store) if checkout
        else
          list = autosubscribe_list(user.store)
        end

        subscribe_to_list(user, list)
      end

      #override as we subscribe during checkout (not login/register)
      def update_exact_target_lists
        return unless params.key? :exact_target_list

        @user = @checkout.order.user if @user.nil? && !@checkout.nil?

        params[:exact_target_list].each do |id, subscribe|

          list = ExactTargetList.find(id)

          if @user.nil? && !@checkout.nil? #guest checkout
            if subscribe == "true"
              #subscribe
              subscribe_to_list(@checkout.email, list)
            else
              #unsubscribe
              unsubscribe_from_list(@checkout.email, list)
            end
          else #normal checkout
            if subscribe == "true"
              #subscribe
              unless @user.exact_target_lists.include? list
                subscribe_to_list(@user, list)
              end
            else
              #unsubscribe
              if @user.exact_target_lists.include? list
                unsubscribe_from_list(@user, list)
              end
            end
          end
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
        begin
          external_key = Spree::Config["#{user.store.code.upcase}_ET_new_account"]
          variables = {:First_Name => "Customer", :emailaddr => user.email}
          Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), user.email, external_key, variables)

        rescue ET::Error => error
          puts "Error sending ExactTarget triggered email"
          puts error.to_yaml
        end
      end
    end

    ETOrderObserver.class_eval do

      def after_hold(order, transition)
        avs = Spree::Config[:hold_order_with_avs].split(",").each(&:strip!)

        if order.payments.any? {|payment| payment.txns.any? { |txn| !avs.include?(txn.avs_response) } }
          begin
            external_key = Spree::Config["#{order.store.code.upcase}_ET_order_security"]
            variables =  {:First_Name => order.bill_address.firstname, :Last_name => order.bill_address.lastname}
            Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), order.checkout.email, external_key, variables)

          rescue ET::Error => error
            puts "Error sending ExactTarget triggered email"
            puts error.to_yaml
          end
        end
      end

      def after_ship(order, transition)
        begin
          external_key = Spree::Config["#{order.store.code.upcase}_ET_order_shipped"]
          view = ActionView::Base.new(Spree::ExtensionLoader.view_paths)
          variables = {:First_Name => order.bill_address.firstname,
                       :Last_name => order.bill_address.lastname,
                       :SENDTIME__CONTENT1 => view.render("order_mailer/order_shipped_plain", :order => order),
                       :SENDTIME__CONTENT2 => view.render("order_mailer/order_shipped_html", :order => order)}

          Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), order.checkout.email, external_key, variables)
       rescue ET::Error => error
         puts "Error sending ExactTarget triggered email"
         puts error.to_yaml
       end
      end

    end

    User.class_eval do
      belongs_to :store

      attr_accessible :store_id

      def deliver_password_reset_instructions!(current_domain)
        reset_perishable_token!
        UserMailer.deliver_password_reset_instructions(self, current_domain)
      end
    end

    UserMailer.class_eval do
      def password_reset_instructions(user, current_domain)
        subject         Spree::Config[:site_name] + ' ' + I18n.t("password_reset_instructions")
        from            Spree::Config[:mails_from]
        recipients      user.email
        sent_on         Time.now
        body            :user => user, :current_domain => current_domain
      end
    end

    PasswordResetsController.class_eval do
      def create
        @user = User.find_by_email(params[:email])
        if @user
          @user.deliver_password_reset_instructions! @current_domain
          flash[:notice] = t("password_reset_instructions_are_mailed")
          redirect_to root_url
        else
          flash[:error] = t("no_user_found")
          render :action => :new
        end
      end
    end

    Admin::OrdersController.class_eval do
      after_filter :ensure_shipment_has_number, :only => [:create, :update]

      private
      def initialize_order_events
        @order_events = %w{cancel hold approve resume reship}
      end

      def ensure_shipment_has_number
        @order.shipment.generate_shipment_number(true)
        @order.shipment.save!
      end
    end

    ShippingMethod.class_eval do
      #adds additional handling fee
      alias_method :core_calculate_cost, :calculate_cost
      alias_method :core_available_to_order?, :available_to_order?

      #add handling_fee or free for can_be_free calculators.
      def calculate_cost(shipment)
        if can_be_free && shipment.order.line_items.total > Spree::Config.get("#{shipment.order.store.code}_free_shipping_at").to_f
          0.0 #aka FREE!
        else
          core_calculate_cost(shipment) + handling_fee.to_f
        end

      end

      #excludes PO (APO / FPO) boxes
      def available_to_order?(order)
        po_regex = /\b((A|a|F|f)?[P|p](OST|ost)?\.?\s?[O|o|0](ffice|FFICE)?\.?\s)?([B|b][O|o|0][X|x])\s(\d+)/

        if self.name.upcase.include?("UPS") && (order.ship_address.address1 =~ po_regex || order.ship_address.address2 =~ po_regex)
          return false
        else
          core_available_to_order?(order)
        end
      end
    end

    #Need to redirect to delivery step on failure (not the default payment)
    Spree::PaypalExpress.module_eval do
      def paypal_payment
        load_object
        opts = all_opts(@order, params[:payment_method_id], 'payment')
        opts.merge!(address_options(@order))
        gateway = paypal_gateway

        response = gateway.setup_authorization(opts[:money], opts)
        unless response.success?
          gateway_error(response)
          redirect_to edit_order_checkout_url(@order, :step => "delivery")
          return
        end

        redirect_to (gateway.redirect_url_for response.token, :review => payment_method.preferred_review)
      end
    end

    #set variables for dashboard tables
    Admin::OverviewController.class_eval do
      before_filter :load_orders, :only => :index

      private
      def load_orders
        @problem_orders = Shipment.find(:all, :group => "order_id", :having => "state = 'unable_to_ship' AND created_at = max(created_at)").map(&:order).uniq

        @vancouver_orders = Order.find(:all, :include => 'shipments', :conditions => ["orders.state != 'shipped' AND shipments.state = 'needs_fulfilment'"])
      end
    end

    #manually touch all credits / charges (workaround for Rails STI issue)
    ::Adjustment
    ::Charge
    ::Credit
    ::TaxCharge
    ::ShippingCharge
    ::CouponCredit
    ::ReturnAuthorizationCredit
    ::FreebieCredit

    Admin::AdjustmentsController.class_eval do
      def list_adjustment_types
        @adjustment_types ||= [
            [ 'Credits', ["FreebieCredit"] ],
            [ 'Charges', ["TaxCharge", "ShippingCharge"]]
          ]
      end
    end

    Admin::UsersController.class_eval do
      before_filter :load_stores

      private
      def load_stores
        @stores = Store.all.collect {|s| [s.name, s.id ]}
      end
    end

    #support short SEO taxon urls
    TaxonsController.class_eval do
      before_filter :redirect_root_taxons, :only => :show

      private

      def redirect_root_taxons
        session[:last_taxon_permalink] = @taxon.permalink #used for products controller to maintain trail
        redirect_to ActionController::Base.relative_url_root, :status => :moved_permanently if @taxon.root?
      end

      def object
        if params.key? "id"
          @object ||= end_of_association_chain.find_by_permalink(params[:id].join("/") + "/")
        else
          permalink = request.path[1..-1]
          permalink += "/" unless permalink[-1..-1] == "/"
          @object ||= end_of_association_chain.find(:first, :include => :taxonomy, :conditions => ["taxons.permalink = ? AND taxonomies.store_id = ?", permalink  , @site.id])
        end
      end

      def accurate_title
        return nil if @taxon.nil?

        @taxon.title.blank? ?  @taxon.name : @taxon.title
      end
    end

    #support short SEO taxon urls
    SeoAssist.class_eval do
      def self.call(env)
        request = Rack::Request.new(env)
        params = request.params
        taxon_id = params['taxon']

        if !taxon_id.blank? && !taxon_id.is_a?(Hash) && @taxon = Taxon.find(taxon_id)
          params.delete('taxon')
          query = build_query(params)
          return [301, { 'Location'=> "/t/#{@taxon.permalink}?#{query}" }, []]
        elsif env["PATH_INFO"] =~ /^\/products\/\S+\/$/
          return [301, { 'Location'=> env["PATH_INFO"][0...-1] }, []] #ensures no trailing / for product urls
        elsif env["PATH_INFO"] =~ /^\/t\/\S+\/$/ || env["PATH_INFO"] =~ /^\/b\/\S+\/$/ || env["PATH_INFO"] =~ /^\/c\/\S+\/$/
          return [301, { 'Location'=> env["PATH_INFO"][0...-1] }, []] #ensures no trailing / for taxon urls
        end
        [404, {"Content-Type" => "text/html"}, "Not Found"]
      end
    end

    #ensure we have new user object for custom login.
    UserSessionsController.class_eval do
      layout 'checkouts'
      before_filter :new_user, :only => [:create, :new]

      private
      def new_user
        @user = User.new
      end
    end

    #set default country_id (around geo_locate ext)
    ApplicationHelper.module_eval do
      def country_id
        Rails.cache.fetch("country_for_#{request.remote_ip}") { country_from_ip(request.remote_ip).id rescue 214 }
      end
    end

    #force shipments to be found via their numbers (not ids)
    Admin::ShipmentsController.class_eval do
      private

      def object
        return @object unless params.has_key? :id
        @object ||= end_of_association_chain.find_by_param!(params[:id])
      end
    end

    Api::ShipmentsController.class_eval do
      private

      def object
        @object ||= end_of_association_chain.find_by_number(params[:id]) if params[:id]
      end
    end

    LineItem.class_eval do
      has_many :reminder_messages, :as => :remindable
    end

    ActionView::Base.send :include, MetaTagHelper


    #simplified address comparsion to exclude first/lastname and phone, make it case insensitve
    Address.class_eval do
      def ==(other_address)
        self_attrs = self.attributes
        other_attrs = other_address.respond_to?(:attributes) ? other_address.attributes : {}

        [self_attrs, other_attrs].each do |attrs|
          attrs.except!("firstname", "lastname", "phone", "id", "created_at", "updated_at", "order_id")
        end
        self_attrs.all? { |key, value| other_attrs[key].to_s.downcase == value.to_s.downcase}
      end
    end
 end

end
