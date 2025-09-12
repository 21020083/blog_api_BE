class Blog < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :comments, dependent: :destroy

  include Votable
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]


  enum :status, { draft: "draft", published: "published" }
  validates :title, presence: true, uniqueness: true
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validate :category_must_be_leaf

  before_validation :default_status

  private

  def default_status
    self.status = :draft if self.status.blank?
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end

  def category_must_be_leaf
    if category.present? && category.children.any?
      errors.add(:category, "must be a leaf category")
    end
  end
end
