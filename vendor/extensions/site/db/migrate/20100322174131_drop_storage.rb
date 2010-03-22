class DropStorage < ActiveRecord::Migration
  def self.up
    remove_column :products, :storage
  end

  def self.down
    add_column :products, :storage, :textto
  end
end