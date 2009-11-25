# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class SiteExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/site"
 
  def self.require_gems(config)
    config.gem 'right_aws'
  end
 
  def activate
		Image.attachment_definitions[:attachment][:storage] = :s3
		Image.attachment_definitions[:attachment][:s3_credentials] = "#{RAILS_ROOT}/vendor/extensions/site/config/s3.yml"
		Image.attachment_definitions[:attachment][:bucket] = "nwb"
		Image.attachment_definitions[:attachment][:path] = ":attachment/:id/:style.:extension"
    Image.attachment_definitions[:attachment].delete :url
  end
end
