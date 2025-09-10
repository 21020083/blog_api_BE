class CreateBlogs < ActiveRecord::Migration[8.0]
  def change
    create_table :blogs do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.references :user, null: false, foreign_key: true
      t.string :slug
      t.string :status, null: false, default: "draft"

      t.timestamps
    end
    add_index :blogs, :slug, unique: true
  end
end
