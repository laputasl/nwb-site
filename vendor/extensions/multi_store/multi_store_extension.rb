# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

# ------------------------------------------------------------------------------------
# NOTE: This is a placeholder for the future multi store extension.  I needed to add
# some functionality to the GA that was particular to multi store and didn't feel
# like jamming it into site extension only to tease it out again.  We'll put the rest
# of the multi store stuff in here eventually.
# ------------------------------------------------------------------------------------

class MultiStoreExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/site"

  # Please use site/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end

  def activate

    # sample custom goal
    # OrdersController.class_eval do
    #   create.before << :fire_goal
    #
    #   private
    #   def fire_goal
    #     flash[:analytics] = "/goal/add-to-cart"
    #   end
    # end

    Tracker.class_eval do
      belongs_to :store

      def self.current
        trackers = Tracker.find(:all, :conditions => {:active => true, :environment => ENV['RAILS_ENV']})
debugger
        trackers.select { |t| t.store.name == Spree::Config[:site_name] }.first
      end
    end

    # make your helper avaliable in all views
    # Spree::BaseController.class_eval do
    #   helper YourHelper
    # end
  end
end
