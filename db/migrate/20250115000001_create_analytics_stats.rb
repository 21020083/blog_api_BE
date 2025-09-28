class CreateAnalyticsStats < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_stats do |t|
      # Basic info
      t.string :period, null: false, limit: 10  # day, week, month, year
      t.date :period_date, null: false          # Start date of the period

      # Filters
      t.bigint :user_id, null: true             # Filter theo user (null = all users)
      t.bigint :category_id, null: true         # Filter theo category (null = all categories)

      # Stats data (JSON to store flexible data)
      t.json :top_views_data, null: false       # [{blog_id, title, views_count, user_name}, ...]
      t.json :top_likes_data, null: false       # [{blog_id, title, likes_count, user_name}, ...]
      t.json :summary_data, null: false         # {total_blogs, total_views, total_likes, ...}

      # Metadata
      t.integer :total_blogs_count, default: 0
      t.integer :total_views_count, default: 0
      t.integer :total_likes_count, default: 0
      t.integer :data_version, default: 1       # Version to handle schema changes

      # Timestamps
      t.datetime :calculated_at, null: false    # When the calculation was performed
      t.timestamps
    end

    # Indexes for performance
    add_index :analytics_stats, [ :period, :period_date ], name: 'index_analytics_stats_on_period_and_date'
    add_index :analytics_stats, [ :period, :user_id, :period_date ], name: 'index_analytics_stats_on_period_user_date'
    add_index :analytics_stats, [ :period, :category_id, :period_date ], name: 'index_analytics_stats_on_period_category_date'
    add_index :analytics_stats, [ :calculated_at ], name: 'index_analytics_stats_on_calculated_at'

    # Unique constraint to prevent duplicates
    add_index :analytics_stats, [ :period, :period_date, :user_id, :category_id ],
              unique: true, name: 'index_analytics_stats_unique'
  end
end
