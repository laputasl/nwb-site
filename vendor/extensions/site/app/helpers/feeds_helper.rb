module FeedsHelper
  def category_names prod
    deepest = prod.taxons.inject(nil) do |memo, tax|
      unless tax.permalink.match(/^c\//).nil?
        unless memo.nil?
          this_parts = tax.permalink.split("/")
          that_parts = memo.permalink.split("/")
          if this_parts.size > that_parts.size
            memo = tax
          end
        else
          memo = tax
        end        
      end
      memo
    end
    unless deepest.nil?
      names = deepest.ancestors.map do |tax|
        if tax.permalink.split("/").size > 1
          tax.name
        else
          nil
        end
      end
      names << deepest.name
      names.compact 
    else
      []
    end
  end
  
  def product_brand_name prod
    brand = prod.taxons.detect do | tax|
      !tax.permalink.match(/^b\//).nil?
    end
    brand.name unless brand.nil?
  end
  
end