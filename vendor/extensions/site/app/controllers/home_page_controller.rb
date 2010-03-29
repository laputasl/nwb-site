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
        @best_selling_cats = Product.find(Taxon.find([9998,3002]).map(&:product_ids).inject {|x, y| x &  y })
        @best_selling_dogs = Product.find(Taxon.find([9998,3001]).map(&:product_ids).inject {|x, y| x &  y })
      else
        @best_selling_products = Product.active.find_all_by_store_id(@site.id, :limit => 10)
      end

      render :partial => "#{@site.code}_show", :layout => true
    end
  end
end
