class Category < ApplicationRecord
  has_many :blogs

  belongs_to :parent_category, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: "parent_category_id", dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :parent_category_id }
  validates :slug, presence: true, uniqueness: { scope: :parent_category_id }

  before_validation :set_slug

  scope :root_categories, -> { where(parent_category_id: nil) }
  
  def set_slug
    self.slug ||= name.to_slug.normalize.to_s.parameterize if name.present?
  end


  def self.by_slug(slugs)
    current = nil
    slugs.each do |slug|
      current = if current
                  current.children.includes(:children).find_by(slug: slug)
                else
                  Category.where(parent_category_id: nil).includes(:children).find_by(slug: slug)
                end
          Rails.logger.debug "Result: #{current&.id}"
      break unless current
    end
    current
  end
end
