class HomePageController < Spree::BaseController
  helper :products

  def show

    #TODO: Figure out what criteria we will use to display products on homepages.
    if @site.code == "pwb"
      @best_selling_cats = Taxon.find_by_name("Cat Supplies").products.active.find(:all, :limit => 2)
      @best_selling_dogs = Taxon.find_by_name("Dog Supplies").products.active.find(:all, :limit => 2)
    else
      @best_selling_products = Product.active.find_all_by_store_id(@site.id, :limit => 10)
    end

    render :partial => "#{@current_domain}_show", :layout => true
  end
end
