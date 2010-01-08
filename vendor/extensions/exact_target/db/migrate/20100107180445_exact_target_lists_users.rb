class ExactTargetListsUsers < ActiveRecord::Migration
  def self.up
    create_table :exact_target_lists_users, :id => false do |t|
      t.references :user
      t.references :exact_target_list
      t.timestamps
    end
  end

  def self.down
  end
end