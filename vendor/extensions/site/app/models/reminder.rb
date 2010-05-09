class Reminder < ActiveRecord::Base
  validates_presence_of :name
  has_many :reminder_messages
end
