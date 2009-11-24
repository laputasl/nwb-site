class AddTaxonFields < ActiveRecord::Migration
  def self.up
    add_column :taxons, :title, :string
    add_column :taxons, :meta_description, :text
    add_column :taxons, :meta_keywords, :string
    add_column :taxons, :footer, :text
  end

  def self.down
    remove_column :taxons, :footer
    remove_column :taxons, :meta_keywords
    remove_column :taxons, :meta_description
    remove_column :taxons, :title
  end
end