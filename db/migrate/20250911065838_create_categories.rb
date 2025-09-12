class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :slug
      t.references :parent_category, foreign_key: { to_table: :categories }, index: true

      t.timestamps
    end
    add_index :categories, :slug, unique: true
  end
end
