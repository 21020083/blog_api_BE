class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :username
      t.string :name
      t.string :email
      t.string :encrypted_password, null: false, default: ""
      t.integer :role
      t.string :jti, null: false
      t.timestamps null: false

      t.index :email, unique: true
      t.index :jti, unique: true
      t.index :name, unique: true
    end
  end
end
