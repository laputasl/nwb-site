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

            lookup(ip)

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
              lookup(ip)

              if res.length < 4
                mapping.update_attribute("iso", res)
                return res
              else
                IpMapping.create(:ip_address => ip) if res.include? "IP_NOT_FOUND"
                return nil
              end
            end
          end
        rescue => e
          return nil
        end
      end

      def lookup(ip)
        url = URI.parse("geoip3.maxmind.com/a?l=#{Spree::Config[:geo_ip_key]}&i=#{ip}")
        req = Net::HTTP::Get.new(url.path)
        res = Net::HTTP.new(url.host, url.port).start do |http|
          http.open_timeout = 3
          http.read_timeout = 3
          http.request(req)
        end

        res
      end
    end
  end
end
