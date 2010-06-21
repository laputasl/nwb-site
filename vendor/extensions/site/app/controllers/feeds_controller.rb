class FeedsController < Spree::BaseController
  helper FeedsHelper
  def show
    feed_name = params[:feed]

    store =  Store.find_by_code(@current_domain)
    products = store.products.active
    all_products = Product.active
    respond_to do |format|
      format.xml  { render :template => "feeds/#{feed_name}.xml",  :layout => false, :locals =>{:products => products, :all_products => all_products, :store => store}}
      format.csv  { render :template => "feeds/#{feed_name}.csv",  :layout => false, :locals =>{:products => products, :all_products => all_products, :store => store}}
      format.atom { render :template => "feeds/#{feed_name}.atom", :layout => false, :locals =>{:products => products, :all_products => all_products, :store => store}}
    end
  end
  
  def includes
    @supress_cart = true
    @title = "Search Results"
    locals = {}
    case params[:segment]
    when "head"
      render :template => "feeds/includes.html.erb", :layout => "/shared/_head.html", :locals =>locals
    when "navigation"
      render :template => "feeds/includes.html.erb", :layout => "/shared/_#{@current_domain}_navigation.html", :locals =>locals
    when "sidebar"
      render :template => "feeds/includes.html.erb", :layout => "/shared/_#{@current_domain}_sidebar.html", :locals =>locals
    when "footer"
      render :template => "feeds/includes.html.erb", :layout => "/shared/_#{@current_domain}_footer.html", :locals =>locals
    when "analytics"
      render :template => "feeds/includes.html.erb", :layout => "/shared/analytics.html", :locals =>locals      
    end
  end
  
end
