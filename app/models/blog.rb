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
  has_noticed_notifications model_name: "Noticed::Notification"

  include Votable
  include Auditable
  include AnalyticsOptimized
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]


  enum :status, { draft: "draft", published: "published" }
  validates :title, presence: true, uniqueness: true
  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validate :category_must_be_leaf

  before_validation :default_status

  # core top views and likes methods
  def self.top_by_views(range:, user_id: nil, category_id: nil, limit: 50)
    # Hybrid approach: smart caching based on period type
    period = detect_period_type(range)

    case period
    when "day"
      # Real-time query for current day (most accurate)
      realtime_top_views(range: range, user_id: user_id, category_id: category_id, limit: limit)
    when "week", "month", "year"
      # Use pre-calculated analytics for better performance
      cached_top_views_by_period(period: period, user_id: user_id, category_id: category_id, limit: limit)
    else
      # Fallback to real-time for custom ranges
      realtime_top_views(range: range, user_id: user_id, category_id: category_id, limit: limit)
    end
  end

  # Real-time query for accurate period-specific data
  def self.realtime_top_views(range:, user_id: nil, category_id: nil, limit: 50)
    query = joins(:blog_views)
            .where(blog_views: { viewed_at: range })
            .where(status: :published)

    query = query.where(blog_views: { user_id: user_id }) if user_id.present?
    query = query.where(category_id: category_id) if category_id.present?

    query
      .select("blogs.*, COUNT(blog_views.id) AS period_views_count")
      .includes(:category, :user)
      .group("blogs.id")
      .order("period_views_count DESC")
      .limit(limit)
  end

  # Cached query using pre-calculated analytics
  def self.cached_top_views_by_period(period:, user_id: nil, category_id: nil, limit: 50)
    period_date = case period
    when "week" then Date.current.beginning_of_week.to_date
    when "month" then Date.current.beginning_of_month.to_date
    when "year" then Date.current.beginning_of_year.to_date
    end

    stat = AnalyticsStat.find_by(
      period: period,
      period_date: period_date,
      user_id: user_id,
      category_id: category_id
    )

    return Blog.none unless stat&.fresh?

    stat.top_views(limit: limit)
  end

  # Detect period type from range
  def self.detect_period_type(range)
    return "day" if range.begin == Time.current.beginning_of_day && range.end == Time.current.end_of_day
    return "week" if range.begin == Time.current.beginning_of_week && range.end == Time.current.end_of_week
    return "month" if range.begin == Time.current.beginning_of_month && range.end == Time.current.end_of_month
    return "year" if range.begin == Time.current.beginning_of_year && range.end == Time.current.end_of_year
    "custom"
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

  # Optimized methods for better performance
  # Legacy method - now uses hybrid approach
  def self.top_views_cached(limit: 10, category_id: nil)
    # Use total views for all-time top blogs
    query = where(status: :published)
    query = query.where(category_id: category_id) if category_id.present?

    query
      .includes(:category, :user)
      .order(views_count: :desc)
      .limit(limit)
  end

  # Legacy method - now uses realtime_top_views
  def self.top_views_realtime(limit: 10, hours: 24, category_id: nil)
    start_time = hours.hours.ago
    range = start_time..Time.current

    realtime_top_views(range: range, category_id: category_id, limit: limit)
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


  def summary(limit: 150)
    ActionView::Base.full_sanitizer.sanitize(content).truncate(limit, separator: /\s/)
  end

  # Performance testing helper methods
  def self.benchmark_top_views(range:, user_id: nil, category_id: nil, limit: 50)
    puts "Testing Blog.top_by_views performance..."
    puts "Range: #{range.begin} to #{range.end}"
    puts "User ID: #{user_id || 'All'}"
    puts "Category ID: #{category_id || 'All'}"
    puts "Limit: #{limit}"
    puts "-" * 50

    time = Benchmark.measure do
      result = top_by_views(range: range, user_id: user_id, category_id: category_id, limit: limit)
      puts "Results: #{result.count} blogs found"
    end

    puts "Execution time: #{time.real.round(3)} seconds"
    puts "User time: #{time.utime.round(3)} seconds"
    puts "System time: #{time.stime.round(3)} seconds"
    puts "Total time: #{time.total.round(3)} seconds"
    puts "=" * 50

    time
  end

  def self.benchmark_comparison(range:, limit: 50)
    puts "Performance Comparison for range: #{range.begin} to #{range.end}"
    puts "=" * 60

    Benchmark.bm(25) do |x|
      x.report("Real-time Query:") do
        realtime_top_views(range: range, limit: limit)
      end

      x.report("Cached Query:") do
        cached_top_views_by_period(period: "week", limit: limit)
      end

      x.report("Total Views (Legacy):") do
        where(status: :published).order(views_count: :desc).limit(limit)
      end
    end
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
