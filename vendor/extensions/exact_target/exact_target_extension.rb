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
      include Spree::ExactTarget

      show.before << :get_exact_target_lists
      new_action.before << :get_exact_target_lists
      after_filter :update_exact_target_lists, :only => [:create, :update]

      private
      def get_exact_target_lists
        @exact_target_lists = ExactTargetList.find(:all, :conditions => {:visible => true})
      end

      def update_exact_target_lists

        params[:exact_target_list].each do |id, subscribe|

          list = ExactTargetList.find(id)

          if subscribe == "true"
            #subscribe
            unless @user.exact_target_lists.include? list
              @user.exact_target_lists << list if subscribe_to_list(@user, list.list_id)
            end
          else
            #unsubscribe
            if @user.exact_target_lists.include? list
              @user.exact_target_lists.delete(list) if unsubscribe_from_list(@user, list.list_id)
            end
          end
        end

      end

    end
  end
end
