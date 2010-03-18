#This is just a stub for data import, will need to be removed when the real Google Checkout EXT is implemented
class GoogleAccount < ActiveRecord::Base
  has_many :payments, :as => :source

  def actions
    []
  end

  # fix for Payment#payment_profiles_supported?
  def payment_gateway
    false
  end
end
