class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :blog_views, [ :viewed_at, :blog_id ], name: 'index_blog_views_on_viewed_at_and_blog_id'
    add_index :blog_views, [ :user_id, :viewed_at ], name: 'index_blog_views_on_user_id_and_viewed_at'
    add_index :blogs, [ :category_id, :views_count ], name: 'index_blogs_on_category_id_and_views_count'
    add_index :blogs, [ :status, :views_count ], name: 'index_blogs_on_status_and_views_count'
    add_index :votes, [ :votable_type, :votable_id, :created_at ], name: 'index_votes_on_votable_and_created_at'
    add_index :votes, [ :voter_id, :voter_type, :created_at ], name: 'index_votes_on_voter_and_created_at'
  end
end
