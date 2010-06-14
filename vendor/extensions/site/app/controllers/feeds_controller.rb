class FeedsController < Spree::BaseController
  helper FeedsHelper
  def show
    feed_name = params[:feed]
    render :template => 'feeds/sli',:layout => false, :locals =>{:products => Product.active}
  end
end
