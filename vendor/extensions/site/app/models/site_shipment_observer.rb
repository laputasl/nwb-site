class SiteShipmentObserver < ActiveRecord::Observer
  observe :shipment

  def after_transmit(shipment, transition)
    trigger = ET::TriggeredSend.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))

    external_key = (shipment.order.store.code == "nwb" ? "nwb-orderexport" : "pwb-custorderexport")
    result = trigger.deliver(shipment.order.checkout.email, external_key, { :First_Name => shipment.order.bill_address.firstname,
                                                                        :Last_name => shipment.order.bill_address.lastname,
                                                                        :SENDTIME__CONTENT2 => "Your order has been received by our warehouse and is being processed for shipping."})
  end

end
