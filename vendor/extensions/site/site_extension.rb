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
		Image.attachment_definitions[:attachment][:s3_credentials] = "#{RAILS_ROOT}/config/s3.yml"
		Image.attachment_definitions[:attachment][:bucket] = "nwb"
		Image.attachment_definitions[:attachment][:path] = ":attachment/:id/:style.:extension"
    Image.attachment_definitions[:attachment].delete :url
  end
  
  Admin::ProductsController.class_eval do
    def additional_fields
      load_object
      @countries = Country.find(:all).sort
    end
    
    before_filter :add_additional_fields
    
    private
    def add_additional_fields
      @product_admin_tabs << {:name => "Additional Fields", :url => "additional_fields_admin_product_url"}
    end
  end
  
 
end
