module Spree
  module ExactTarget
    def autosubscribe_list
      ExactTargetList.find(:first, :conditions => ["subscribe_all_new_users = ?", true])
    end

    def create_subscriber(user)
      list = autosubscribe_list

      if list.nil?
        subscriber_id = -1
      else
        subscriber = ET::Subscriber.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

        begin
          subscriber_id = subscriber.add(user.email, list.list_id, {:Customer_ID => user.id, :Customer_ID_NWB => user.id, :Customer_ID_PWB => user.id})
          user.exact_target_lists << list
          user.save!
        rescue
          subscriber_id = -1
        end
      end

      user.exact_target_subscriber_id = subscriber_id
      user.save!
    end

    def subscribe_to_list(user, listid)
      subscriber = ET::Subscriber.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

      begin
        subscription_id = subscriber.add(user.email, listid).inspect

        return true
      rescue ET::Error => error
        if error.code == 14 #already subscribed
          return true
        else
          return false
        end
      end
    end

    def unsubscribe_from_list(user, listid)
      subscriber = ET::Subscriber.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

      begin
        result = subscriber.delete(nil, user.email, listid).inspect

        return true
      rescue ET::Error => error
        if error.code == 1 #not subscribed
          return true
        else
          return false
        end
      end
    end

  end
end