class AddLegacyIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :legacy_id, :integer
    add_column :users, :status, :string
  end

  def self.down
    remove_column :users, :status
    remove_column :users, :legacy_id
  end
end