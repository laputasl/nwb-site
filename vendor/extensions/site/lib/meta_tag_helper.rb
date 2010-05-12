module MetaTagHelper

  # Renders a meta tag for use in the HEAD section of an html document to indicate that page should not be indexed
  def meta_skip
    if request.env["REQUEST_PATH"] =~ /\/login|\/pets|\/people|\/orders|\/users/
      tag :meta, :name => "ROBOTS", :content => "NOINDEX, NOFOLLOW"
    end
  end

end