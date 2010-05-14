class ETOrderObserver < ActiveRecord::Observer
  observe :order

  #update subscriber with bill_address details after order is completed.
  def after_complete(order, transition)
    Delayed::Job.enqueue DelayedSubscriberUpdate.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password), order.number)
  end

end
