class SiteShipmentObserver < ActiveRecord::Observer
  observe :shipment

  def after_transmit(shipment, transition)
    begin
      external_key = Spree::Config["#{shipment.order.store.code.upcase}_ET_order_exported"]
      view = ActionView::Base.new(Spree::ExtensionLoader.view_paths)
      variables = { :First_Name => shipment.order.bill_address.firstname,
                    :Last_name => shipment.order.bill_address.lastname,
                    :SENDTIME__CONTENT1 => view.render("order_mailer/order_exported_plain", :order => shipment.order),
                    :SENDTIME__CONTENT2 => view.render("order_mailer/order_exported_html", :order => shipment.order)}

      Delayed::Job.enqueue DelayedSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), shipment.order.checkout.email, external_key, variables)

    rescue Exception => error
      puts "Error calling ExactTarget trigger"
      puts error.to_yaml
    end

  end

end
