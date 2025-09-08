class DeviseCreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      # Username làm khóa xác thực chính (unique, null: false)
      t.string :username, null: false
      t.string :email, null: false
      t.string :name, null: false
      t.integer :role, null: false, default: 1

      # Database authenticatable
      t.string :encrypted_password, null: false, default: ""

      # Recoverable (reset password)
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      # Rememberable (nhớ đăng nhập)
      t.datetime :remember_created_at

      # Trackable (tùy chọn: theo dõi đăng nhập)
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      # JWT (bắt buộc cho devise-jwt)
      t.string :jti, null: false

      # Timestamps
      t.timestamps null: false
    end

    # Indexes
    add_index :users, :username, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :jti, unique: true
  end
end