class DelayedSubscriberUpdate < Struct.new(:username, :password, :order)
  include Spree::ExactTarget

  def perform
    unless order.user.nil?
      order.user.reload #reload the user to be sure we have the most uptodate record

      if order.user.exact_target_subscriber_id.nil?
        create_subscriber(order.user)
      end

      if order.user.exact_target_subscriber_id.to_i > 0
        subscriber = ET::Subscriber.new(username, password)
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

      end
    end

  end
end