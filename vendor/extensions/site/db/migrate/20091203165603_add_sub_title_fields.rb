class AddSubTitleFields < ActiveRecord::Migration
  def self.up
    add_column :products, :subtitle_home, :text
    add_column :products, :subtitle_category, :text
    add_column :products, :featured_testimonial, :text
  end

  def self.down
    remove_column :products, :featured_testimonial
    remove_column :products, :subtitle_home, :text
    remove_column :products, :subtitle_category, :text
  end
end