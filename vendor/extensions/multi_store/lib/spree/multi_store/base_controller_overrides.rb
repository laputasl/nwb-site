module Spree::MultiStore::BaseControllerOverrides
  def self.included(controller)
    controller.prepend_before_filter :set_layout, :load_global_taxons
    controller.helper :products, :taxons

    unless ActionController::Base.consider_all_requests_local
      controller.rescue_from Exception, :with => :render_error
    end
  end


  private

  # Tell Rails to look in layouts/#{@site} whenever we're inside of a store (instead of the standard /layouts location)
  def find_layout(layout, format, html_fallback=false) #:nodoc:
    layout_dir = @current_domain ? "layouts/#{@current_domain}" : "layouts"
    view_paths.find_template(layout.to_s =~ /\A\/|layouts\// ? layout : "#{layout_dir}/#{layout}", format, html_fallback)
  rescue ActionView::MissingTemplate
    raise if Mime::Type.lookup_by_extension(format.to_s).html?
  end

  def set_layout
    @site ||= Store.find(:first, :conditions => {:code => request.headers['wellbeing-site']})
    @current_domain = request.headers['wellbeing-domain']
    # self.class.layout @current_domain
  end

  def get_taxonomies
    @taxonomies ||= Taxonomy.find(:all, :include => {:root => :children}, :conditions => ["store_id = ?", @site.id])
    @taxonomies
  end

  def load_global_taxons
    @categories = Taxonomy.find(:first, :conditions => {:store_id => @site.id, :name => "Category"})
  end

  def render_error(exception)
    log_error(exception)
    if request.path == "/"
      #error on the homepage can't redirect to it.
      render :file => "#{RAILS_ROOT}/public/500.html", :status => 500
    else
      flash[:error] = "We're sorry, but something went wrong."
      redirect_to "/"
    end
  end
end