class Blog < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  include Votable

  enum :status, { draft: "draft", published: "published" }
  validates :title, presence: true, uniqueness: true
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, :default_status

  private

  def generate_slug
    self.slug ||= title.parameterize if title.present?
  end

  def default_status
    self.status = :draft if self.status.blank?
  end

  def url_by_slug
    Rails.application.routes.url_helpers.blog_path(self)
  end
end
