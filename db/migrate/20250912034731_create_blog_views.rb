class CreateBlogViews < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_views do |t|
      t.references :blog, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.datetime :viewed_at, null: false

      t.timestamps
    end

    add_index :blog_views, [ :blog_id, :user_id, :viewed_at ]
  end
end
