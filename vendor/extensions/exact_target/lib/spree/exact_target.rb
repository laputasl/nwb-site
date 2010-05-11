module Spree
  module ExactTarget
    def autosubscribe_list
      ExactTargetList.find(:first, :conditions => ["subscribe_all_new_users = ?", true])
    end

    def create_subscriber(user)
      list = autosubscribe_list
      subscribe_to_list(user, list)
    end

    def subscribe_to_list(user, list)
      Delayed::Job.enqueue DelayedSubscriberAdd.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), user, list)
    end

    def unsubscribe_from_list(user, list)
      Delayed::Job.enqueue DelayedSubscriberDelete.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), user, list)
    end

    private
    #CONTROLLER Actions
    def get_exact_target_lists
      @exact_target_lists = ExactTargetList.find(:all, :conditions => {:visible => true})
    end

    def update_exact_target_lists
      return unless params.key? :exact_target_list
      params[:exact_target_list].each do |id, subscribe|

        list = ExactTargetList.find(id)

        if subscribe == "true"
          #subscribe
          unless @user.exact_target_lists.include? list
            subscribe_to_list(@user, list)
          end
        else
          #unsubscribe
          if @user.exact_target_lists.include? list
            unsubscribe_from_list(@user, list)
          end
        end
      end

    end
  end
end