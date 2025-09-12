class Tag < ApplicationRecord
  has_many :blog_tags, dependent: :destroy
  has_many :blogs, through: :blog_tags

  validates :name, presence: true, uniqueness: true
end
