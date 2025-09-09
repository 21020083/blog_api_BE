class AddInfoToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :role, :integer, default: 1
  end
end
