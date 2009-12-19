class HomePageController < Spree::BaseController
  helper :products

  def show
    if @site.code == "pwb"
      @best_selling_cats = Taxon.find_by_name("Cat Supplies").products[0...2]
      @best_selling_dogs = Taxon.find_by_name("Dog Supplies").products[0...2]

      render :partial => "#{@site.code}_show", :layout => true
    else
      redirect_to products_path
    end


  end
end
