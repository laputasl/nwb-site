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
      include Spree::BaseControllerOverrides
      include Spree::ExactTarget

      show.before << :get_exact_target_lists
      new_action.before << :get_exact_target_lists
      after_filter :update_exact_target_lists, :only => [:create, :update]

    end

    CheckoutsController.class_eval do
      include Spree::BaseControllerOverrides
      include Spree::ExactTarget

      before_filter :get_exact_target_lists, :only =>:register
      after_filter :update_exact_target_lists, :only => [:create, :update]

    end

    ActionMailer::Base.class_eval do
      def self.method_missing(method_symbol, *parameters) #:nodoc:
        if match = matches_dynamic_method?(method_symbol)
          if match[1] == 'deliver'
            mailer = new(match[2], *parameters)
            variables = YAML::load(mailer.body)
            external_key = variables.delete "external_key"

            unless external_key.nil?
              begin
                trigger = ET::TriggeredSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))
                result = trigger.deliver(mailer.mail.to, external_key, variables)
              rescue ET::Error => error

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
