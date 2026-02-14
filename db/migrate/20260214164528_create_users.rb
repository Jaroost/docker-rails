class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :email
      t.string :username
      t.string :first_name
      t.string :last_name
      t.text :token
      t.text :refresh_token
      t.datetime :token_expires_at
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, [ :provider, :uid ], unique: true
    add_index :users, :email, unique: true
  end
end
