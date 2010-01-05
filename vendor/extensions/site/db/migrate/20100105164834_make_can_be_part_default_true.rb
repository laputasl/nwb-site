class MakeCanBePartDefaultTrue < ActiveRecord::Migration
  def self.up
    change_column_default :products, :can_be_part, true
  end

  def self.down
    change_column_default :products, :can_be_part, false
  end
end