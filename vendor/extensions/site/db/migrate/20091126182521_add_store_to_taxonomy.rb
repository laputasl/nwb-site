class AddStoreToTaxonomy < ActiveRecord::Migration
  def self.up
    add_column :taxonomies, :store, :string
  end

  def self.down
    remove_column :taxonomies, :store
  end
end