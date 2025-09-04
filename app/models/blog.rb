class Blog < ApplicationRecord
  # Associations
  belongs_to :user, optional: false

  has_many :comments, dependent: :destroy
  # Enums
  enum :status, { draft: "draft", published: "published" }

  # Validations
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :content, presence: true
  validates :user, presence: true
  validates :status, presence: true

  # Callbacks
  before_validation :generate_slug
  before_validation :set_default_status

  acts_as_votable

  # Scopes
  scope :published, -> { where(status: :published) }
  scope :draft, -> { where(status: :draft) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def restore
    update(deleted_at: nil)
  end

  private

  def generate_slug
    return if slug.present?
    base_slug = title.parameterize
    count = Blog.where("slug LIKE ?", "#{base_slug}%").count
    self.slug = count.positive? ? "#{base_slug}-#{count + 1}" : base_slug
  end

  def set_default_status
    self.status ||= :draft
  end
end
