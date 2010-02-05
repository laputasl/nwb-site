class HomePageController < Spree::BaseController
  helper :products

  def show

    #TODO: Figure out what criteria we will use to display products on homepages.
    if @site.code == "pwb"
      @best_selling_cats = Taxon.find_by_name("Cat Supplies").products.active[0...2]
      @best_selling_dogs = Taxon.find_by_name("Dog Supplies").products.active[0...2]
    else
      @best_selling_products = Product.active.find_all_by_store_id(@site.id)[0...10]
    end

    render :partial => "#{@site.code}_show", :layout => true
  end
end
