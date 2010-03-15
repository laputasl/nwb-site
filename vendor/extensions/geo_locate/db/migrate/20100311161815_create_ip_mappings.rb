class CreateIpMappings < ActiveRecord::Migration
  def self.up
    create_table :ip_mappings do |t|
      t.string :ip_address
      t.string :iso
    end
  end

  def self.down
    drop_table :ip_mappings
  end
end
