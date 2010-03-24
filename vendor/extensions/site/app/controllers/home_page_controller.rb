class HomePageController < Spree::BaseController
  helper :products
  include Spree::Search
  def show
    if @current_domain != @site.code

      @taxon = Taxonomy.find(:first, :conditions => {:store_id => @site.id, :name => "Category"}).root
      retrieve_products

      if @site.code == "pwb"
        @taxon.name = "Pet Products"
      else
        @taxon.name = "People Products"
      end

      render :template => "taxons/show"
    else
      #TODO: Figure out what criteria we will use to display products on homepages.
      if @site.code == "pwb"
        @best_selling_cats = Taxon.find_by_name("Cat Supplies").products.active.find(:all, :limit => 2)
        @best_selling_dogs = Taxon.find_by_name("Dog Supplies").products.active.find(:all, :limit => 2)
      else
        @best_selling_products = Product.active.find_all_by_store_id(@site.id, :limit => 10)
      end

      render :partial => "#{@site.code}_show", :layout => true
    end
  end
end
