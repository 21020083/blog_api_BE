module AnalyticsOptimized
  extend ActiveSupport::Concern

  included do
    # Optimized scopes for analytics
    scope :published, -> { where(status: "published") }
    scope :with_views_in_range, ->(range) {
      joins(:blog_views).where(blog_views: { viewed_at: range })
    }
    scope :with_likes_in_range, ->(range) {
      joins("LEFT JOIN votes ON blogs.id = votes.votable_id AND votes.votable_type = 'Blog' AND votes.vote_flag = true")
        .where(votes: { created_at: range })
    }
  end

  class_methods do
    def top_by_views_optimized(range:, user_id: nil, category_id: nil, limit: 50)
      query = published.with_views_in_range(range)

      query = query.where(blog_views: { user_id: user_id }) if user_id.present?
      query = query.where(category_id: category_id) if category_id.present?

      query.select("blogs.*, COUNT(blog_views.id) AS views_count")
           .includes(:category, :user)
           .group("blogs.id")
           .order("views_count DESC")
           .limit(limit)
    end

    def top_by_likes_optimized(range:, user_id: nil, category_id: nil, limit: 50)
      query = published.with_likes_in_range(range)

      query = query.where("votes.voter_id = ?", user_id) if user_id.present?
      query = query.where(category_id: category_id) if category_id.present?

      query.select("blogs.*, COUNT(votes.id) AS likes_count")
           .includes(:category, :user)
           .group("blogs.id")
           .order("likes_count DESC")
           .limit(limit)
    end

    def analytics_summary(period: "day", limit: 10)
      range = case period
      when "day" then Time.current.beginning_of_day..Time.current.end_of_day
      when "week" then Time.current.beginning_of_week..Time.current.end_of_week
      when "month" then Time.current.beginning_of_month..Time.current.end_of_month
      when "year" then Time.current.beginning_of_year..Time.current.end_of_year
      end

      {
        top_views: top_by_views_optimized(range: range, limit: limit),
        top_likes: top_by_likes_optimized(range: range, limit: limit),
        total_views: published.with_views_in_range(range).count,
        total_likes: published.with_likes_in_range(range).count
      }
    end
  end

  # Instance methods for individual blog analytics
  def views_in_period(period)
    range = case period
    when "day" then Time.current.beginning_of_day..Time.current.end_of_day
    when "week" then Time.current.beginning_of_week..Time.current.end_of_week
    when "month" then Time.current.beginning_of_month..Time.current.end_of_month
    when "year" then Time.current.beginning_of_year..Time.current.end_of_year
    end

    blog_views.where(viewed_at: range).count
  end

  def likes_in_period(period)
    range = case period
    when "day" then Time.current.beginning_of_day..Time.current.end_of_day
    when "week" then Time.current.beginning_of_week..Time.current.end_of_week
    when "month" then Time.current.beginning_of_month..Time.current.end_of_month
    when "year" then Time.current.beginning_of_year..Time.current.end_of_year
    end

    votes.where(created_at: range, vote_flag: true).count
  end

  def performance_metrics
    {
      total_views: views_count,
      unique_views: blog_views.where.not(user_id: nil).select(:user_id).distinct.count,
      total_likes: votes.where(vote_flag: true).count,
      views_today: views_in_period("day"),
      likes_today: likes_in_period("day"),
      views_this_week: views_in_period("week"),
      likes_this_week: likes_in_period("week")
    }
  end
end
