# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class SiteExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/site"

  def self.require_gems(config)
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

      def allow_pay?
        return false if suspicious_order?
        checkout_completeYeah
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
          self.comments.create(:title => "Order On Hold", :comment => "Held as suspicious because AVS code is not white listed.", :user => admin)

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
          transition :from => ['transmitted', 'acknowledged', 'needs_fulfilment', 'ready_to_ship'], :to => 'unable_to_ship'
        end
        after_transition :to => 'shipped', :do => :transition_order
      end

      private
      def check_order_state
        self.ready! if (order.paid? && !inventory_units.any? {|unit| unit.backordered? })
      end
    end

    OrdersController.class_eval do
      before_filter :set_analytics
      create.before << :assign_to_store
      update.before :check_for_removed_items
      update.after :recalculate_totals

      update do
        flash nil
        success.wants.html { redirect_to (@from_checkout ? edit_order_checkout_url(object, :step => "delivery")  : edit_order_url(object)) }
        failure.wants.html { render :template => "orders/edit" }
      end

      def calculate_shipping
        load_object
        if params.key? :zipcode
          addr = Address.new(:zipcode => params[:zipcode], :country_id => 214, :state_name => "")
        else
          addr = Address.new(:zipcode => "", :country_id => params[:country_id], :state_name => "")
        end
        addr.save(false)
        @order.checkout.update_attribute(:ship_address_id, addr.id)

        begin

          rates = ShippingMethod.all_available(@order).collect do |ship_method|
            { :id => ship_method.id,
              :name => ship_method.name,
              :rate => ship_method.calculate_cost(@order.checkout.shipment),
              :position => ship_method.position }
          end
        rescue Spree::ShippingError => ship_error
          flash[:error] = ship_error.to_s
          rates = []
        end

        rates = rates.sort_by{ |r| r[:position] }

        if rates.size > 0 && @order.checkout.shipping_method_id.nil?
          @order.checkout.update_attribute(:shipping_method_id, rates[0][:id])
        end

        render :json => rates.to_json
      end

      private
      def assign_to_store
        @order.store = @site
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
        self.bill_address = ship_address.clone
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

        if !params[:order_by_price].blank?
          @product_group = ProductGroup.new.from_route([params[:order_by_price]+"_by_master_price"])
        elsif params[:product_group_name]
          @cached_product_group = ProductGroup.find_by_permalink(params[:product_group_name])
          @product_group = ProductGroup.new
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

        base_scope = @cached_product_group ? @cached_product_group.products.active : Product.active
        base_scope = base_scope.on_hand unless Spree::Config[:show_zero_stock_products]
        @products_scope = @product_group.apply_on(base_scope)

        curr_page = Spree::Config.searcher.manage_pagination ? params[:page] : 1
        @products = @products_scope.all.paginate({
            :include  => [:images, :master],
            :per_page => per_page,
            :page     => curr_page
          })
        @products_count = @products_scope.count

        return(@products.uniq)
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

      update.before :clear_payments_if_in_payment_state, :correct_state_values

      before_filter :update_shipping_method, :only => [:paypal_payment]
      before_filter :set_analytics
      before_filter :get_exact_target_lists, :only => [:edit]
      before_filter :enforce_registration, :except => [:register, :set_shipping_method]

      # sets shipping medthod for checkout when using paypal payment option
      def set_shipping_method
        render :json => update_shipping_method
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
        if object.delivery?
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
        @available_methods = rate_hash
        @checkout.shipping_method_id ||= @available_methods.first[:id] unless @available_methods.empty?
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

        @checkout.order.shipping_charges.each(&:destroy) #remove all old shipping charges

        if @checkout.update_attribute(:shipping_method_id, params[:shipping_method])
          @checkout.order.update_totals!
          true
        else
          false
        end
      end

      #returns rates sorted by :position
      def rate_hash
        begin
          rates = @checkout.shipping_methods.collect do |ship_method|
            { :id => ship_method.id,
              :name => ship_method.name,
              :rate => ship_method.calculate_cost(@order.checkout.shipment),
              :position => ship_method.position }
          end

          rates.sort_by{ |r| r[:position] }
        rescue Spree::ShippingError => ship_error
          flash[:error] = ship_error.to_s
          []
        end
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
          begin
            subscriber = ET::Subscriber.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

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

      #override as we subscribe during checkout (not login/register)
      def update_exact_target_lists
        return unless params.key? :exact_target_list

        @user = @checkout.order.user

        params[:exact_target_list].each do |id, subscribe|

          list = ExactTargetList.find(id)

          if @user.nil? #guest checkout
            if subscribe == "true"
              #subscribe
              subscribe_to_list(@checkout.email, list.list_id)
            else
              #unsubscribe
              unsubscribe_from_list(@checkout.email, list.list_id)
            end
          else #normal checkout
            if subscribe == "true"
              #subscribe
              unless @user.exact_target_lists.include? list
                @user.exact_target_lists << list if subscribe_to_list(@user, list.list_id)
              end
            else
              #unsubscribe
              if @user.exact_target_lists.include? list
                @user.exact_target_lists.delete(list) if unsubscribe_from_list(@user, list.list_id)
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
          trigger = ET::TriggeredSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

          external_key = (user.store.code == "nwb" ? "nwb-accountinfo" : "pwb-accountInfo")
          result = trigger.deliver(user.email, external_key, {:First_Name => "Customer", :emailaddr => user.email})
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
            trigger = ET::TriggeredSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

            external_key = (order.store.code == "nwb" ? "nwb-ordersecurity" : "pwb-custordersecurity")
            result = trigger.deliver(order.checkout.email, external_key, { :First_Name => order.bill_address.firstname,
                                                                           :Last_name => order.bill_address.lastname})
          rescue ET::Error => error
            puts "Error sending ExactTarget triggered email"
            puts error.to_yaml
          end
        end
      end

      def after_ship(order, transition)
        begin
          trigger = ET::TriggeredSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

          external_key = (order.store.code == "nwb" ? "nwb-ordershipped" : "pwb-custordershipped ")
          view = ActionView::Base.new(Spree::ExtensionLoader.view_paths)
          result = trigger.deliver(order.checkout.email, external_key, { :First_Name => order.bill_address.firstname,
                                                                         :Last_name => order.bill_address.lastname,
                                                                         :SENDTIME__CONTENT1 => view.render("order_mailer/order_shipped_plain", :order => order),
                                                                         :SENDTIME__CONTENT2 => view.render("order_mailer/order_shipped_html", :order => order)})
       rescue ET::Error => error
         puts "Error sending ExactTarget triggered email"
         puts error.to_yaml
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
      #after_filter :assign_to_store, :only => [:new, :create, :update]

      private
      def initialize_order_events
        @order_events = %w{cancel hold approve resume reship}
      end

      # def assign_to_store
      #   @order.update_attribute(:store_id, Store.find_by_code("nwb").id) if @order.store.nil?
      # end
    end

    ShippingMethod.class_eval do
      #adds additional handling fee
      alias_method :core_calculate_cost, :calculate_cost

      #add handling_fee or free for can_be_free calculators.
      def calculate_cost(shipment)
        if can_be_free && shipment.order.line_items.total > Spree::Config.get("#{shipment.order.store.code}_free_shipping_at").to_f
          0.0 #aka FREE!
        else
          core_calculate_cost(shipment) + handling_fee.to_f
        end

      end

      #excludes PO (APO / FPO) boxes
      def available_to_address?(address)
        po_regex = /\b((A|a|F|f)?[P|p](OST|ost)?\.?\s?[O|o|0](ffice|FFICE)?\.?\s)?([B|b][O|o|0][X|x])\s(\d+)/

        if self.name.upcase.include?("UPS") && (address.address1 =~ po_regex || address.address2 =~ po_regex)
          return false
        else
          available? && zone.include?(address)
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

    #redirect /products url (except when searching)
    ProductsController.class_eval do
      before_filter :redirect_products_path_to_home, :only => :index

      def redirect_products_path_to_home
        return if params.key? :keywords
        redirect_to '/', :status => 301 if ['/products', '/products/'].include? request.path
      end

      private
      def accurate_title
        return nil if @product.nil?

        @product.page_title.blank? ?  @product.name : @product.page_title

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
        (country_from_ip(request.remote_ip) || Country.find(214) ).id
      end
    end


 end

end
