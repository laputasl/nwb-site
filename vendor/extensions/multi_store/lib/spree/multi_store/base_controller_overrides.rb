module Spree::MultiStore::BaseControllerOverrides
  def self.included(controller)
    controller.prepend_before_filter :set_layout, :load_global_taxons
    controller.helper :products, :taxons
  end

  private

  # Tell Rails to look in layouts/#{@site} whenever we're inside of a store (instead of the standard /layouts location)
  def find_layout(layout, format, html_fallback=false) #:nodoc:
    layout_dir = @current_domain ? "layouts/#{@current_domain}" : "layouts"
    view_paths.find_template(layout.to_s =~ /\A\/|layouts\// ? layout : "#{layout_dir}/#{layout}", format, html_fallback)
  rescue ActionView::MissingTemplate
    raise if Mime::Type.lookup_by_extension(format.to_s).html?
  end

  def set_layout
    @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
    @current_domain = request.headers['wellbeing-domain']
    # self.class.layout @current_domain
  end

  def get_taxonomies
    @taxonomies ||= Taxonomy.find(:all, :include => {:root => :children}, :conditions => ["store_id = ?", @site.id])
    @taxonomies
  end

  def load_global_taxons
    @categories = Taxonomy.find(:first, :conditions => {:store_id => @site.id, :name => "Category"})

    rates = get_shipping_rates
  end

  def get_shipping_rates
    @shipping_calculator_rates = []
    return @shipping_calculator_rates if session[:order_id].blank?
    order = find_order

    if !session[:zipcode].blank?
      addr = Address.new(:zipcode => session[:zipcode], :country_id => 214, :state_name => "")
    elsif !session[:country_id].blank?
      addr = Address.new(:zipcode => "", :country_id => session[:country_id], :state_name => "")
    end

    return if addr.nil?

    addr.save(false)
    order.checkout.update_attribute(:ship_address_id, addr.id)

    begin

      rates = ShippingMethod.all_available(order).collect do |ship_method|
        { :id => ship_method.id,
          :name => ship_method.name,
          :rate => ship_method.calculate_cost(order.checkout.shipment),
          :position => ship_method.position }
      end
    rescue Spree::ShippingError => ship_error
      flash[:error] = ship_error.to_s
      rates = []
    end

    if rates.size > 0 && (order.checkout.shipping_method_id.nil? || !rates.map{|r| r[:id]}.include?(order.checkout.shipping_method_id))
      session[:shipping_method_id] = rates[0][:id]
      session[:shipping_method_rate] = rates[0][:rate]
      order.checkout.update_attribute(:shipping_method_id, rates[0][:id])
    end

    @shipping_calculator_rates = rates
  end
end