class FeedsController < Spree::BaseController
  helper FeedsHelper
  def show
    # response.headers['Content-type'] = 'text/xml; charset=utf-8'
    feed_name = params[:feed]
    respond_to do |format|
      format.xml { render :template => "feeds/#{feed_name}", :layout => false, :locals =>{:products => Product.active}}
    end
  end
end
