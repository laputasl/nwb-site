class DelayedSubscriberAdd < Struct.new(:username, :password, :user, :list)
  def perform
    subscriber = ET::Subscriber.new(username, password)

    if list.nil?
      subscriber_id = -1
    else
      begin
        subscriber = ET::Subscriber.new(username, password)

        if user.is_a? String
          subscriber_id = subscriber.add(user, list.list_id)
        else
          subscriber_id = subscriber.add(user.email, list.list_id, {:Customer_ID => user.id, :Customer_ID_NWB => user.id, :Customer_ID_PWB => user.id})
        end
      rescue ET::Error => error
        if error.code == 14 #already subscribed
          #need to find actual subscriber_id
          subscriber_id = 0
        else
          subscriber_id = -1
        end
      end
    end

    unless user.is_a? String
      user.exact_target_subscriber_id = subscriber_id
      user.exact_target_lists << list
      user.save!
    end

  end
end