class Comment < ApplicationRecord
  acts_as_votable
  belongs_to :user
  belongs_to :blog
  belongs_to :parent_comment, class_name: 'Comment', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: :parent_comment_id, dependent: :destroy

  validates :comment_text, presence: true
   
  
  scope :root_comments, -> { where(parent_comment_id: nil) }
  
end