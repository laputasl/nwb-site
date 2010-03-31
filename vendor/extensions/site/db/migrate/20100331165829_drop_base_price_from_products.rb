class DropBasePriceFromProducts < ActiveRecord::Migration
  def self.up
    remove_column :products, :base_price
  end

  def self.down
    add_column :products, :base_price, :decimal, :default => 0.0
  end
end