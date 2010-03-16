#this is a catch all payment source object
class OtherPayment < ActiveRecord::Base
  has_many :payments, :as => :source

  def actions
    []
  end
end
