TaxonsHelper.module_eval do
  def breadcrumbs(taxon, separator="&nbsp;:&nbsp;")

    crumbs = [content_tag(:li, "Your Location")]

    if @current_domain != @site.code
      crumbs << content_tag(:li, separator + link_to(t(:home) , "/") )

      if @site.code == 'pwb'
        crumbs << content_tag(:li, separator + link_to("Pets", root_path) )
      else
        crumbs << content_tag(:li, separator + link_to("People", root_path) )
      end

    else
      crumbs << content_tag(:li, separator + link_to(t(:home), root_path) )
    end

    if taxon
      taxons = taxon.ancestors
      taxons.delete_at(0)
      crumbs << taxons.collect { |ancestor| content_tag(:li, separator + link_to(ancestor.name , seo_url(ancestor))) } unless taxons.empty?
      crumbs << content_tag(:li, separator + content_tag(:span, taxon.name))

    end
    content_tag(:ul, crumbs.flatten.map{|li| li.mb_chars}.join, :id => 'breadcrumbs')
  end

  def taxon_header(taxon)
    taxons = taxon.ancestors
    taxons.delete_at(0)
    taxons << taxon
    taxons.map(&:name).join(": ")
  end

end