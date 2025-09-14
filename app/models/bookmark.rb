class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :blog

  validates :user_id, uniqueness: { scope: :blog_id }

  after_commit :notify_blog_owner, on: :create

  private

  def notify_blog_owner
    return if blog.user == user
    BookmarkNotificationNotifier.with(bookmark: self).deliver(blog.user)
  end
end
