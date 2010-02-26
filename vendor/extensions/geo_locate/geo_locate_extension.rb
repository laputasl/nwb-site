# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class GeoLocateExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/geo_locate"

  # Please use geo_locate/config/routes.rb instead for extension routes.

  def self.require_gems(config)
    config.gem "geoip", :version => '0.8.6'
  end

  def activate
    ApplicationHelper.module_eval do

      def country_from_ip(ip)
        Country.find_by_iso(country_code_from_ip ip)
      end

      def country_code_from_ip(ip)
        geo_db_path = File.join(RAILS_ROOT, "vendor", "extensions", "geo_locate", "db", "GeoIP.dat")

        if FileTest.exist? geo_db_path
          begin
            result = GeoIP.new(geo_db_path).country(ip)
            return nil if result.size < 4
            return nil if result[3] == "--"
            return result[3]
          rescue Exception => e
            return nil
          end
        else
          return nil
        end
      end
    end
  end
end
