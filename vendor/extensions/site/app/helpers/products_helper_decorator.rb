ProductsHelper.module_eval do
  def seo_url(taxon, product = nil)
    return "#{ActionController::Base.relative_url_root}/t/" + taxon.permalink if product.nil?
  end

  def buy_button(product, css_class = "btn btnBuyNowSml")
    if product.has_variants?
      link_to("Buy Now", product, :class => css_class)
    else
      hidden_field_tag("variants[#{product.master.id}]", 1) +
      submit_tag("Buy Now", :class => css_class)
    end
  end

end