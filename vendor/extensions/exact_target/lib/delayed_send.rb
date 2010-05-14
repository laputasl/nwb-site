class DelayedSend < Struct.new(:username, :password, :email, :external_key, :attributes)
  def perform
    return if email.blank?

    begin
      trigger = ET::TriggeredSend.new(username, password)
      trigger.deliver(email, external_key, attributes)
    rescue ET::Error => error
      if error.code != 128 #blacklisted user, so can't send email
        raise #re-raise error again for all other codes (so delayed_job will log)
      end
    end
  end
end