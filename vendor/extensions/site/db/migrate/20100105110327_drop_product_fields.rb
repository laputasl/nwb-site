class DropProductFields < ActiveRecord::Migration
  def self.up
    remove_column :products, :subtitle_home
    remove_column :products, :subtitle_category
    remove_column :products, :subtitle_subcategory
    remove_column :products, :subtitle_brand
    remove_column :products, :short_category
    remove_column :products, :short_subcategory
    remove_column :products, :short_brand
    remove_column :products, :export_description_broad
    remove_column :products, :export_description_specific
    remove_column :products, :country_id
    remove_column :products, :tarrif_code
  end

  def self.down
    add_column :products, :tarrif_code, :string
    add_column :products, :country_id, :integer
    add_column :products, :export_description_specific, :string
    add_column :products, :export_description_broad, :string
    add_column :products, :short_brand, :text
    add_column :products, :short_subcategory, :text
    add_column :products, :short_category, :text
    add_column :products, :subtitle_brand, :text
    add_column :products, :subtitle_subcategory, :text
    add_column :products, :subtitle_home, :text
    add_column :products, :subtitle_category, :text
  end
end