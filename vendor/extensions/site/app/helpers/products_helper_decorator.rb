ProductsHelper.module_eval do
  def seo_url(taxon, product = nil)
    return "#{ActionController::Base.relative_url_root}/" + taxon.permalink if product.nil?
  end

  def buy_button(product, css_class = "btn btnBuyNowSml")
    if product.has_variants?
      link_to("Buy Now", product, :class => css_class)
    else
      hidden_field_tag("variants[#{product.master.id}]", 1) +
      submit_tag("Buy Now", :class => css_class)
    end
  end

  def estimate_shipping_day()
    now = Time.new()
    Time.zone = "PST"

    if Time.zone.at(now).hour < 14
      if Time.zone.at(now).wday < 6 && Time.zone.at(now).wday > 0
        "Today"
      else
        "Monday"
      end
    else
      if Time.zone.at(now).wday < 5 && Time.zone.at(now).wday > 0
        "Tomorrow"
      else
        "Monday"
      end
    end
  end

  def free_shipping_at(order, store)
    free_at = Spree::Config.get("#{store.code}_free_shipping_at").to_f

    if order.line_items.total <= free_at
      "Spend #{number_to_currency(free_at-order.line_items.total)} more for Free Shipping at #{number_to_currency(free_at)} (US orders only) "
    else
      "Free Shipping available (US orders only) "
    end
  end
end