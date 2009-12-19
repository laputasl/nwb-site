class AddBasePriceToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :base_price, :decimal, :default => 0.0
  end

  def self.down
    remove_column :products, :base_price
  end
end