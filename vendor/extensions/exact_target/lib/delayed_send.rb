class DelayedSend < Struct.new(:username, :password, :email, :external_key, :attributes)
  def perform
    trigger = ET::TriggeredSend.new(username, password)
    trigger.deliver(email, external_key, attributes)
  end
end