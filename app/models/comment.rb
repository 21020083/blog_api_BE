class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :blog
  belongs_to :parent_comment, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_comment_id, dependent: :destroy

  include Votable
  include Auditable
  validates :comment_text, presence: true
  validates :user_id, presence: true
  validates :blog_id, presence: true

  after_create_commit :notify_blog_owner
  before_destroy :store_snapshot

  scope :root_comments, -> { where(parent_comment_id: nil) }

  def reply?
    parent_comment_id.present?
  end

  private

  def store_snapshot
    @comment_snapshot = {
      'id' => id,
      'content' => content,
      'user_id' => user_id,
      'blog_id' => blog_id
    }
  end

  def notify_blog_owner
    CommentNotifier.with(comment: self).deliver_later(blog.user)  
  end

  def notify_blog_owner_destroy
    CommentNotifier.with(comment: @comment_snapshot).deliver_later(blog.user)
  end
end
