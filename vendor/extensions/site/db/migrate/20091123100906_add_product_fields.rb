class AddProductFields < ActiveRecord::Migration
  def self.up
    add_column :products, :legacy_id, :integer
    add_column :products, :short_home, :string
    add_column :products, :anchor_name, :string
    add_column :products, :short_category, :string
    add_column :products, :short_subcategory, :string
    add_column :products, :short_brand, :string
    add_column :products, :sales_copy, :string
    add_column :products, :dosage, :string
    add_column :products, :storage, :string
    add_column :products, :ingredients, :string
    add_column :products, :warning, :string
    add_column :products, :package_description, :string
    add_column :products, :subtitle_main, :string
    add_column :products, :subtitle_subcategory, :string
    add_column :products, :subtitle_brand, :string
    add_column :products, :units_of_measure, :string
    add_column :products, :reminder, :integer
    add_column :products, :export_description_broad, :string
    add_column :products, :export_description_specific, :string
    add_column :products, :country_id, :integer
    add_column :products, :tarrif_code, :string
  end

  def self.down
    remove_column :products, :legacy_id
    remove_column :products, :tarrif_code
    remove_column :products, :country_id
    remove_column :products, :export_description_specific
    remove_column :products, :export_description_broad
    remove_column :products, :reminder
    remove_column :products, :units_of_measure
    remove_column :products, :subtitle_brand
    remove_column :products, :subtitle_subcategory
    remove_column :products, :subtitle_main
    remove_column :products, :package_description
    remove_column :products, :warning
    remove_column :products, :ingredients
    remove_column :products, :storage
    remove_column :products, :dosage
    remove_column :products, :sales_copy
    remove_column :products, :short_brand
    remove_column :products, :short_subcategory
    remove_column :products, :short_category
    remove_column :products, :short_home
    remove_column :products, :anchor_name
  end
end