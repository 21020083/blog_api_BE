class Blog < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :comments, dependent: :destroy
  include Votable

  enum :status, { draft: "draft", published: "published" }
  validates :title, presence: true, uniqueness: true
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :slug, presence: true, uniqueness: true
  validate :category_must_be_leaf

  before_validation :generate_slug, :default_status

  scope :by_id_or_slug, ->(value) { where("id = :value OR slug = :value", value: value)}

  private

  def generate_slug
    self.slug ||= title.to_slug.normalize.to_s.parameterize if title.present?
  end

  def default_status
    self.status = :draft if self.status.blank?
  end

  def url_by_slug
    Rails.application.routes.url_helpers.blog_path(self)
  end

  def category_must_be_leaf
    return if category.nil? || category.children.any?

    errors.add(:category, "must be a leaf category")
  end
end
