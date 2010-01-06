require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

class StoreSwitcher
  def self.call(env)
    domain_parts = env['SERVER_NAME'].split(".")
    domain_name = domain_parts.size == 3 ? domain_parts[1] : domain_parts[0]

    remove_path = ""

    if env['PATH_INFO'] =~ /^\/people/
      remove_path = "/people"
      env['wellbeing-site'] = "nwb"
      env['wellbeing-domain'] = "pwb"
    elsif env['PATH_INFO'] =~ /^\/pets/
      remove_path = "/pets"
      env['wellbeing-site'] = "pwb"
      env['wellbeing-domain'] = "nwb"
    else
      env['wellbeing-site'] = case domain_name
        when "petwellbeing" then "pwb"
        when "naturalwellbeing" then "nwb"
        else "nwb"
      end
      env['wellbeing-domain'] = env['wellbeing-site']
    end

    if env['wellbeing-domain'] == "pwb"
      Spree::Config.set(:site_name => "PetWellBeing.com")
    else
      Spree::Config.set(:site_name => "NaturalWellBeing.com")
    end

    ActionController::Base.relative_url_root = remove_path

    [404, {"Content-Type" => "text/html"}, ["Not Found"]]
  end
end
