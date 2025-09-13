class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :blog

  validates :user_id, uniqueness: { scope: :blog_id }

  after_create :notify_blog_owner

  private

  def notify_blog_owner
    return if blog.user == user
    puts "#{self.inspect} #{blog.user.inspect}"
    BookmarkNotificationNotifier.with(bookmark: self).deliver_later(blog.user)
  end
end
