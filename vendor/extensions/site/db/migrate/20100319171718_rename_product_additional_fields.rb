class RenameProductAdditionalFields < ActiveRecord::Migration
  def self.up
    rename_column :products, :package_description, :short_category
  end

  def self.down
    rename_column :products, :short_category, :package_description

  end
end