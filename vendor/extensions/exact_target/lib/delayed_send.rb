class DelayedSend < Struct.new(:username, :password, :email, :external_key, :attributes, :order_number, :plain_view, :html_view)
  def perform
    return if email.blank?

    order = Order.find_by_number(order_number) unless order_number.nil?
    view = ActionView::Base.new(Spree::ExtensionLoader.view_paths)
    attributes[:SENDTIME__CONTENT1] = view.render(plain_view, :order => order) unless plain_view.nil?
    attributes[:SENDTIME__CONTENT2] = view.render(html_view, :order => order) unless html_view.nil?

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