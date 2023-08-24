class CreateWallets < ActiveRecord::Migration[7.0]
  def change
    create_table :wallets do |t|
      t.string :stake_address, index: true
      t.datetime :last_connected_at, null: false

      t.timestamps
    end
  end
end
