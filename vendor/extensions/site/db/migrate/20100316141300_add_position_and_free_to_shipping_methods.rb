class AddPositionAndFreeToShippingMethods < ActiveRecord::Migration
  def self.up
    add_column :shipping_methods, :position, :integer, :default => 10
    add_column :shipping_methods, :can_be_free, :boolean, :default => false
  end

  def self.down
    remove_column :shipping_methods, :can_be_free
    remove_column :shipping_methods, :position
  end
end