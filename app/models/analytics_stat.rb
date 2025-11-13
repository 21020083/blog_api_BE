class AnalyticsStat < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  belongs_to :category, optional: true

  # Validations
  validates :period, presence: true, inclusion: { in: %w[day week month year] }
  validates :period_date, presence: true
  validates :calculated_at, presence: true

  # Scopes
  scope :by_period, ->(period) { where(period: period) }
  scope :by_date, ->(date) { where(period_date: date) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :recent, -> { order(calculated_at: :desc) }
  scope :for_period_range, ->(period, start_date, end_date) {
    where(period: period, period_date: start_date..end_date)
  }

  # Class methods
  class << self
    def find_or_calculate(period:, period_date:, user_id: nil, category_id: nil)
      stat = find_by(
        period: period,
        period_date: period_date,
        user_id: user_id,
        category_id: category_id
      )

      return stat if stat&.fresh?

      # Calculate new stats if not found or stale
      calculate_and_save(period: period, period_date: period_date, user_id: user_id, category_id: category_id)
    end

    def calculate_and_save(period:, period_date:, user_id: nil, category_id: nil)
      calculator = AnalyticsCalculator.new(
        period: period,
        period_date: period_date,
        user_id: user_id,
        category_id: category_id
      )

      stats_data = calculator.calculate_all

      create!(
        period: period,
        period_date: period_date,
        user_id: user_id,
        category_id: category_id,
        top_views_data: stats_data[:top_views],
        top_likes_data: [],  # Empty for views-only
        summary_data: stats_data[:summary],
        total_blogs_count: stats_data[:summary][:total_blogs],
        total_views_count: stats_data[:summary][:total_views],
        total_likes_count: 0,  # Zero for views-only
        calculated_at: Time.current
      )
    end

    def cleanup_old_stats(keep_days: 90)
      cutoff_date = keep_days.days.ago.to_date
      where("calculated_at < ?", cutoff_date).delete_all
    end
  end

  # Instance methods
  def fresh?(max_age = nil)
    max_age ||= case period
    when "day" then 2.hours      # Cache 2 giờ cho day (real-time hơn)
    when "week" then 6.hours     # Cache 6 giờ cho week
    when "month" then 1.day      # Cache 1 ngày cho month
    when "year" then 3.days      # Cache 3 ngày cho year
    else 2.hours
    end

    calculated_at > max_age.ago
  end

  # Force refresh analytics data
  def refresh!
    calculator = AnalyticsCalculator.new(
      period: period,
      period_date: period_date,
      user_id: user_id,
      category_id: category_id
    )

    stats_data = calculator.calculate_all

    update!(
      top_views_data: stats_data[:top_views],
      top_likes_data: [],  # Empty for views-only
      summary_data: stats_data[:summary],
      total_blogs_count: stats_data[:summary][:total_blogs],
      total_views_count: stats_data[:summary][:total_views],
      total_likes_count: 0,  # Zero for views-only
      calculated_at: Time.current
    )
  end

  # Return Blog relation
  def top_views(limit: 10)
    return Blog.none if top_views_data.blank?

    # Get blog IDs from data
    blog_ids = top_views_data.first(limit).map { |item| item["blog_id"] || item[:blog_id] }
    return Blog.none if blog_ids.empty?

    # Optimize query - only select needed columns, no includes for now
    Blog.select("blogs.id, blogs.title, blogs.views_count, blogs.created_at, blogs.updated_at, blogs.user_id, blogs.category_id")
        .where(id: blog_ids)
        .order(Arel.sql("FIELD(blogs.id, #{blog_ids.join(',')})"))
  end

  # Return Blog relation
  def top_likes(limit: 10)
    return Blog.none if top_likes_data.blank?

    # Get blog IDs from data
    blog_ids = top_likes_data.first(limit).map { |item| item["blog_id"] || item[:blog_id] }
    return Blog.none if blog_ids.empty?

    # Optimize query - only select needed columns, no includes for now
    Blog.select("blogs.id, blogs.title, blogs.views_count, blogs.created_at, blogs.updated_at, blogs.user_id, blogs.category_id")
        .where(id: blog_ids)
        .order(Arel.sql("FIELD(blogs.id, #{blog_ids.join(',')})"))
  end
end
