class CreateExactTargetTriggers < ActiveRecord::Migration
  def self.up
    create_table :exact_target_triggers do |t|
      t.string :title
      t.string :mailer_method
      t.string :external_key
    end
  end

  def self.down
    drop_table :exact_target_triggers
  end
end
