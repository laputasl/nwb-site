class CreateExactTargetLists < ActiveRecord::Migration
  def self.up
    create_table :exact_target_lists do |t|
      t.integer :list_id
      t.string :title
      t.boolean :subscribe_all_new_users, :default => false
      t.boolean :visible, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :exact_target_lists
  end
end
