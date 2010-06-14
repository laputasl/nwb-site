class FeedsController < Spree::BaseController
  helper FeedsHelper
  def show
    feed_name = params[:feed]
    respond_to do |format|
      format.xml { render :template => "feeds/#{feed_name}", :layout => false, :locals =>{:products => Product.active}}
      format.csv { render :template => "feeds/#{feed_name}.csv", :layout => false, :locals =>{:products => Product.active}}
    end
  end
end
