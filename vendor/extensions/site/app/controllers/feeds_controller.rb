class FeedsController < Spree::BaseController
  helper FeedsHelper
  def show
    feed_name = params[:feed]
    store_code = params[:store]

    # if the feed url referrs to a store (as in /feed/nwb/feed.xml) we get the active products for that store only
    unless store_code.nil?
      products = Store.find_by_code(store_code).products.active
    else
      products = Product.active
    end

    respond_to do |format|
      format.xml { render :template => "feeds/#{feed_name}.xml", :layout => false, :locals =>{:products => products}}
      format.csv { render :template => "feeds/#{feed_name}.csv", :layout => false, :locals =>{:products => products}}
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
      render :template => "feeds/includes.html.erb", :layout => "/shared/_#{@current_domain}_footer.html", :locals =>locals      
    end
  end
  
end
