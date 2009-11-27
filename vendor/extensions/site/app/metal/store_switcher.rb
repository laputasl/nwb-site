require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
require 'rack/utils'

class StoreSwitcher
  def self.call(env)
    session = env['rack.session']
    domain_parts = env['SERVER_NAME'].split(".")
    domain_name = domain_parts.size == 3 ? domain_parts[1] : domain_parts[0]

    remove_path = nil

    if env['PATH_INFO'] =~ /^\/people/
      remove_path = "people"
      session[:store] = "nwb"
      session[:ignore_domain] = true

    elsif env['PATH_INFO'] =~ /^\/pets/
      remove_path = "pets"
      session[:store] = "pwb"
      session[:ignore_domain] = true

	elsif !session[:ignore_domain]
      session[:store] = case domain_name
        when "petwellbeing" then "pwb"
        when "naturalwellbeing" then "nwb"
        else "nwb"
      end
      session[:ignore_domain] = false
    end

    if session[:store] == "pwb"
      Spree::Config.set(:site_name => "petwellbeing.com")
    else
      Spree::Config.set(:site_name => "naturalwellbeing.com")
    end

    session[:started_from] = session[:store] unless session.key? :started_from

	unless remove_path.nil?
      new_path = env['PATH_INFO'].gsub "/#{remove_path}", ""
      env["REQUEST_PATH"] = new_path
      env["REQUEST_URI"]  = new_path
      env["PATH_INFO"]    = new_path
    end

    [404, {"Content-Type" => "text/html"}, ["Not Found"]]
  end
end
