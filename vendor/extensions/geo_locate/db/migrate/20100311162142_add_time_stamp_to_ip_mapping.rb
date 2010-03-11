class AddTimeStampToIpMapping < ActiveRecord::Migration
  def self.up
    add_column :ip_mappings, :created_at, :datetime
    add_column :ip_mappings, :updated_at, :datetime
  end

  def self.down
    remove_column :ip_mappings, :updated_at
    remove_column :ip_mappings, :created_at
  end
end