class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :blog
  belongs_to :parent_comment, class_name: 'Comment', optional: true

  has_many :replies, class_name: 'Comment', foreign_key: 'parent_comment_id', dependent: :destroy
  default_scope { order(created_at: :desc) }

  validates :comment_text, :user, :blog, presence: true
  validates :parent_comment, presence: true, if: -> { parent_comment_id.present? }

  scope :top_level, -> { where(parent_comment_id: nil) }

  private

  def comment_with_replies
    Comment.where(parent_comment_id: id)
  end
end
