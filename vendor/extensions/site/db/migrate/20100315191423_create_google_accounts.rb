class CreateGoogleAccounts < ActiveRecord::Migration
  def self.up
    create_table :google_accounts do |t|
      t.string :email
    end
  end

  def self.down
    drop_table :google_accounts
  end
end
