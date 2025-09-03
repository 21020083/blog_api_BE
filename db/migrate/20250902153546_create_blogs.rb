class CreateBlogs < ActiveRecord::Migration[8.0]
  def change
    create_table :blogs do |t|
      t.string :title
      t.string :slug
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.string :status
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :blogs, :slug, unique: true
    add_index :blogs, :status
  end
end
