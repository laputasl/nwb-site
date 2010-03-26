class ETOrderObserver < ActiveRecord::Observer
  include Spree::ExactTarget
  observe :order

  #update subscriber with bill_address details after order is created.
  def after_update(order)
    if order.new?
      if order.user.nil?
        #guest user
        unless order.checkout.email.nil?
          create_subscriber(order.checkout.email)
        end
      else
        #normal user
        if order.user.exact_target_subscriber_id.nil? || order.user.exact_target_subscriber_id == -1
          create_subscriber(order.user)
          order.user.reload
        end

        if order.user.exact_target_subscriber_id != -1
          begin
            subscriber = ET::Subscriber.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))
            subscriber.update(order.user.exact_target_subscriber_id, order.user.email, nil, {
                :Customer_ID => order.user.id,
                :Customer_ID_NWB => order.user.id,
                :Customer_ID_PWB => order.user.id,
                :First_Name => order.bill_address.firstname,
                :Last_Name => order.bill_address.lastname,
                :Day_Phone => order.bill_address.phone,
                :Postal_Code => order.bill_address.zipcode,
                :City => order.bill_address.city,
                :Province => (order.bill_address.state_id.nil? ? order.bill_address.state_name.to_s : order.bill_address.state.name),
                :Country => order.bill_address.country.name,
                :Last_Purchase_Date => order.completed_at.to_s
            })
          rescue ET::Error => error
            puts "Error updating ExactTarget subscription"
            puts error.to_yaml
          end
        end
      end

    end
  end
end
