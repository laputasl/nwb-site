class ReminderMessage < ActiveRecord::Base
  belongs_to :remindable, :polymorphic => true
  belongs_to :reminder
  belongs_to :user
end
