module Spree
  module BaseControllerOverrides
    def self.included(controller)
      controller.prepend_before_filter :set_layout, :load_global_taxons
      controller.helper :products, :taxons
    end

    private
    def set_layout
      @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
      @current_domain = request.headers['wellbeing-domain']
      self.class.layout @current_domain
    end

    def get_taxonomies
      @taxonomies ||= Taxonomy.find(:all, :include => {:root => :children}, :conditions => ["store_id = ?", @site.id])
      @taxonomies
    end

    def load_global_taxons
      @categories = Taxonomy.find(:first, :conditions => {:store_id => @site.id, :name => "Category"})
    end
  end
end