class CreateOtherPayments < ActiveRecord::Migration
  def self.up
    create_table :other_payments do |t|
      t.text :description
    end
  end

  def self.down
    drop_table :other_payments
  end
end
