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
end
