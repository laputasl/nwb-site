class AddPageTitleToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :page_title, :string
  end

  def self.down
    remove_column :products, :page_title
  end
end