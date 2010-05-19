class SiteShipmentObserver < ActiveRecord::Observer
  observe :shipment

  def after_transmit(shipment, transition)
    begin
      external_key = Spree::Config["#{shipment.order.store.code.upcase}_ET_order_exported"]

      variables = { :First_Name => shipment.order.bill_address.firstname,
                    :Last_name => shipment.order.bill_address.lastname}

      Delayed::Job.enqueue DelayedSend.new( Spree::Config.get(:exact_target_user),
                                            Spree::Config.get(:exact_target_password),
                                            shipment.order.checkout.email,
                                            external_key,
                                            variables,
                                            shipment.order.number,
                                            "order_mailer/order_exported_plain",
                                            "order_mailer/order_exported_html")

    rescue Exception => error
      puts "Error calling ExactTarget trigger"
      puts error.to_yaml
    end

  end

end
