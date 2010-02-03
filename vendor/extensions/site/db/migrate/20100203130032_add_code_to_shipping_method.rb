class AddCodeToShippingMethod < ActiveRecord::Migration
  def self.up
    add_column :shipping_methods, :code, :string
  end

  def self.down
    remove_column :shipping_methods, :code
  end
end