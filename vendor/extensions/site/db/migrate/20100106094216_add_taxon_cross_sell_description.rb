class AddTaxonCrossSellDescription < ActiveRecord::Migration
  def self.up
    add_column :taxons, :cross_sell, :text
  end

  def self.down
    remove_column :taxons, :cross_sell
  end
end