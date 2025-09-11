class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.text :comment_text, null: false
      t.references :user, null: false, foreign_key: true
      t.references :blog, null: false, foreign_key: true
      t.references :parent_comment, foreign_key: { to_table: :comments }, index: true

      t.timestamps
    end
  end
end

