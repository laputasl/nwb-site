TaxonsHelper.module_eval do
  def breadcrumbs(taxon, separator="&nbsp;:&nbsp;")

    crumbs = [content_tag(:li, "Your Location" + separator)]
    crumbs << content_tag(:li, link_to(t(:home) , root_path) + separator)

    if taxon
      taxons = taxon.ancestors
      taxons.delete_at(0)
      crumbs << taxons.collect { |ancestor| content_tag(:li, link_to(ancestor.name , seo_url(ancestor)) + separator) } unless taxons.empty?
      crumbs << content_tag(:li, content_tag(:span, taxon.name))

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