class Category < ApplicationRecord
  has_many :blogs
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :history ]

  belongs_to :parent_category, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: "parent_category_id", dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :parent_category_id }

  before_validation :default_status

  scope :root_categories, -> { where(parent_category_id: nil) }

  def should_generate_new_friendly_id?
    name_changed? || slug.blank?
  end

  def normalize_friendly_id(value)
    value.to_slug.normalize.to_s.parameterize.truncate(80, omission: "")
  end

  def all_descendants
    children.flat_map { |child| [ child ] + child.all_descendants }
  end

  def leaf_descendants
    all_descendants.select { |c| c.children.empty? }
  end

  def blogs_from_leaf_descendants
    Blog.where(category_id: leaf_descendants.map(&:id))
  end
end
