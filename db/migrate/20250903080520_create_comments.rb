class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.text :comment_text
      t.references :user, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true
      t.references :parent_comment, null: true, foreign_key: { to_table: :comments }1123

      t.timestamps
    end
  end
end
