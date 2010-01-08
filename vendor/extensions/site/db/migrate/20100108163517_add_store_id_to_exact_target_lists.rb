class AddStoreIdToExactTargetLists < ActiveRecord::Migration
  def self.up
    add_column :exact_target_lists, :store_id, :integer
  end

  def self.down
    remove_column :exact_target_lists, :store_id
  end
end