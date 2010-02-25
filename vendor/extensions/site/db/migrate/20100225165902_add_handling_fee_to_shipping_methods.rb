class AddHandlingFeeToShippingMethods < ActiveRecord::Migration
  def self.up
    add_column :shipping_methods, :handling_fee, :decimal, :precision => 8, :scale => 2
  end

  def self.down
    remove_column :shipping_methods, :handling_fee
  end
end