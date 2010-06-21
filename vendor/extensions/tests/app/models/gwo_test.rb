class GwoTest < ActiveRecord::Base
  validates_uniqueness_of :name
  validates_uniqueness_of :eid
  validates_uniqueness_of :pid
end
