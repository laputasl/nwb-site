# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class ExactTargetExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/exact_target"

  def activate
    #register ActiveRecord Observer
    ETUserObserver.instance
    ETOrderObserver.instance

    User.class_eval do
      has_and_belongs_to_many :exact_target_lists
    end

    UsersController.class_eval do
      include Spree::MultiStore::BaseControllerOverrides
      include Spree::ExactTarget

      show.before << :get_exact_target_lists
      new_action.before << :get_exact_target_lists
      after_filter :update_exact_target_lists, :only => [:create, :update]

    end

    CheckoutsController.class_eval do
      include Spree::MultiStore::BaseControllerOverrides
      include Spree::ExactTarget

      before_filter :get_exact_target_lists, :only =>:register
      after_filter :update_exact_target_lists, :only => [:create, :update]

    end

    ActionMailer::Base.class_eval do
      def self.method_missing(method_symbol, *parameters) #:nodoc:
        if match = matches_dynamic_method?(method_symbol)
          if match[1] == 'deliver'
            begin
              mailer = new(match[2], *parameters)
              super if mailer.mail.to.nil?

              variables = YAML::load(mailer.body)
              external_key = variables.delete "external_key"
            rescue => exception
              logger.error "Error parsing ExactTarget variables for triggered email"
              logger.error exception.to_yaml
            end

            unless external_key.nil?
              begin
                mailer.mail.to.each do |email|
                  Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), email, external_key, variables)
                end
              rescue ET::Error => error
                logger.error "Error sending ExactTarget triggered email"
                logger.error error.to_yaml
              end
            end
          end
        else
          super
        end
      end

    end


  end
end
