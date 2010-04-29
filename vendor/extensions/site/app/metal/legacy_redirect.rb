# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

class LegacyRedirect
  @legacy_products = /p\d+.cfm$/
  def self.call(env)
    if pos = env["PATH_INFO"] =~ @legacy_products
      # redirect legacy products with url of the form XXXXX-pYY.cfm
      path = env["PATH_INFO"]
      id = path[pos..(path.length)].gsub("p", "").gsub(".cfm", "")
      product = Product.find(:all, :conditions => ["legacy_id = ? AND `from` = ?", id, env['wellbeing-domain']]).first
      if product
        if env["QUERY_STRING"].blank?
          [301, {"Location" => "/products/#{product.permalink}", "Content-Type" => "text/html"}, []]
        else
          [301, {"Location" => "/products/#{product.permalink}?#{env["QUERY_STRING"]}", "Content-Type" => "text/html"}, []]
        end
      else
        [404, {"Content-Type" => "text/html"}, ["Not Found"]]
      end
    else
      [404, {"Content-Type" => "text/html"}, ["Not Found"]]
    end
  end
end