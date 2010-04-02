class AddExtraLegacyIdToUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :legacy_id
    add_column :users, :pwb_legacy_id, :integer
    add_column :users, :nwb_legacy_id, :integer
  end

  def self.down
    remove_column :users, :nwb_legacy_id
    remove_column :users, :pwb_legacy_id
    add_column :users, :legacy_id, :integer
  end
end