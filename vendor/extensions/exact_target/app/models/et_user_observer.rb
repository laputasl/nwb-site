class ETUserObserver < ActiveRecord::Observer
  include Spree::ExactTarget
  observe :user

  def after_create(user)
    create_subscriber(user)
  end
end
