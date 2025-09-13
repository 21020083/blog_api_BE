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

  scope :root_comments, -> { where(parent_comment_id: nil) }

  def reply?
    parent_comment_id.present?
  end
end
