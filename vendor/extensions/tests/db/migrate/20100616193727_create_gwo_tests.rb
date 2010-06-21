class CreateGwoTests < ActiveRecord::Migration
  def self.up
    create_table :gwo_tests do |t|
      t.string :name
      t.string :eid
      t.string :pid
      t.string :category
      t.string :status

      t.timestamps
    end
  end

  def self.down
    drop_table :gwo_tests
  end
end
