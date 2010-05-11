class DelayedSubscriberDelete < Struct.new(:username, :password, :user, :list)
  def perform
    subscriber = ET::Subscriber.new(username, password)

    begin
      if user.is_a? User
        result = subscriber.delete(nil, user.email, list.list_id).inspect
        user.exact_target_lists.delete(list)
      else
        result = subscriber.delete(nil, user, list.list_id).inspect
      end

    rescue ET::Error => error
      # if error.code == 1 #not subscribed
      #
      # end
    end

  end
end