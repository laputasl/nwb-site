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
        Country.find_by_iso(country_code_from_ip(ip))
      end

      def country_code_from_ip(ip)
        mapping = IpMapping.find_by_ip_address(ip)

        begin
          if mapping.nil?

            res = Net::HTTP.get("geoip3.maxmind.com", "/a?l=dGGtRmYrWh5D&i=#{ip}")

            if res.length < 4
              IpMapping.create(:ip_address => ip, :iso => res)
              return res
            else
              IpMapping.create(:ip_address => ip, :iso => "US") if res.include? "IP_NOT_FOUND"
              return nil
            end
          else
            if mapping.updated_at > 7.days.ago
              mapping.iso
            else

              res = Net::HTTP.get("geoip3.maxmind.com", "/a?l=dGGtRmYrWh5D&i=#{ip}")

              if res.length < 4
                mapping.update_attribute("iso", res)
                return res
              else
                IpMapping.create(:ip_address => ip) if res.include? "IP_NOT_FOUND"
                return nil
              end
            end
          end
        rescue
          return nil
        end
      end

    end
  end
end
