class Calculator::FlatOverValue < Calculator
  preference :amount, :decimal, :default => 0
  preference :order_must_be_over, :decimal, :default => 75.00

  def self.description
    I18n.t("flat_rate_over_value")
  end

  def self.register
    super
    ShippingMethod.register_calculator(self)
    ShippingRate.register_calculator(self)
  end

  def compute(object=nil)
    self.preferred_amount
  end

  def available?(order)
    order.total > self.preferred_order_must_be_over
  end
end
