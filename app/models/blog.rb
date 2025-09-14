class Blog < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  has_many :comments, dependent: :destroy
  has_many :blog_views, dependent: :destroy
  has_many :blog_tags, dependent: :destroy
  has_many :tags, through: :blog_tags
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarkers, through: :bookmarks, source: :user
  has_many :notifications, through: :user, dependent: :destroy
  has_many :notification_mentions, through: :user, dependent: :destroy
  has_noticed_notifications model_name: 'Noticed::Notification'

  include Votable
  include Auditable
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]


  enum :status, { draft: "draft", published: "published" }
  validates :title, presence: true, uniqueness: true
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validate :category_must_be_leaf

  before_validation :default_status

  # core top views and likes methods
  def self.top_by_views(range:, user_id: nil, category_id: nil)
    query = joins(:blog_views)
            .where(blog_views: { viewed_at: range })

    query = query.where(blog_views: { user_id: user_id }) if user_id.present?
    query = query.where(category_id: category_id) if category_id.present?

    query
      .select("blogs.*, COUNT(blog_views.id) AS views_count")
      .includes(:category, :user)
      .group("blogs.id")
      .order("views_count DESC")
  end

  def self.top_by_likes(range:, user_id: nil, category_id: nil)
    query = joins("LEFT JOIN votes ON blogs.id = votes.votable_id AND votes.votable_type = 'Blog'")
            .where(votes: { created_at: range })

    query = query.where("votes.voter_id = ?", user_id) if user_id.present?
    query = query.where(category_id: category_id) if category_id.present?

    query
      .select("blogs.*, COUNT(votes.id) AS likes_count")
      .includes(:category, :user)
      .group("blogs.id")
      .order("likes_count DESC")
  end

  # Helper ranges
  RANGES = {
    "day"   => -> { Time.current.beginning_of_day..Time.current.end_of_day },
    "week"  => -> { Time.current.beginning_of_week..Time.current.end_of_week },
    "month" => -> { Time.current.beginning_of_month..Time.current.end_of_month },
    "year"  => -> { Time.current.beginning_of_year..Time.current.end_of_year }
  }.freeze

  # helper methods for top views and likes
  def self.top_by_views_in(period: "day", user_id: nil, category_id: nil)
    # get the range for the period
    range_proc = RANGES[period]
    raise ArgumentError, "Invalid period" unless range_proc

    top_by_views(range: range_proc.call, user_id: user_id, category_id: category_id)
  end

  def self.top_by_likes_in(period: "day", user_id: nil, category_id: nil)
    range_proc = RANGES[period]
    raise ArgumentError, "Invalid period" unless range_proc

    top_by_likes(range: range_proc.call, user_id: user_id, category_id: category_id)
  end

  def log_view(user = nil)
    BlogView.create!(blog: self, user: user, viewed_at: Time.current)
    increment!(:views_count)
  end

  def total_views
    views_count
  end

  def unique_views
    blog_views.where.not(user_id: nil).select(:user_id).distinct.count
  end

  def views_in_range(start_time, end_time)
    blog_views.where(viewed_at: start_time..end_time).count
  end

  def unique_views_in_range(start_time, end_time)
    blog_views.where(viewed_at: start_time..end_time)
              .where.not(user_id: nil)
              .select(:user_id).distinct.count
  end

  def log_view(user = nil)
    BlogView.create!(blog: self, user: user, viewed_at: Time.current)
  end

  def summary(limit: 150)
    ActionView::Base.full_sanitizer.sanitize(content).truncate(limit, separator: /\s/)
  end

  private

  def default_status
    self.status = :draft if self.status.blank?
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end

  def category_must_be_leaf
    if category.present? && !category.is_leaf_category?
      errors.add(:category, "must be a leaf category")
    end
  end
end
