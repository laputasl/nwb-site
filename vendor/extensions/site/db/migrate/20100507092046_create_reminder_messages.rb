class CreateReminderMessages < ActiveRecord::Migration
  def self.up
    create_table :reminder_messages do |t|
      t.references :remindable, :polymorphic => true
      t.references :reminder
      t.references :user
      t.timestamps
    end

    add_index :reminder_messages, [:remindable_id, :remindable_type]
  end

  def self.down
    remove_index :reminder_messages, [:remindable_id, :remindable_type]
    drop_table :reminder_messages
  end
end
