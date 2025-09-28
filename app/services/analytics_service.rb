class AnalyticsService
  include ActiveModel::Model

  PERIODS = %w[day week month year].freeze

  def initialize(period: "day", user_id: nil, category_id: nil, limit: 50)
    @period = period
    @user_id = user_id
    @category_id = category_id
    @limit = limit
  end

  def top_views
    # Sử dụng method có sẵn trong Blog model
    Blog.top_by_views_in(
      period: @period,
      user_id: @user_id,
      category_id: @category_id
    ).where(status: "published").limit(@limit)
  end

  def top_likes
    # Sử dụng method có sẵn trong Blog model
    Blog.top_by_likes_in(
      period: @period,
      user_id: @user_id,
      category_id: @category_id
    ).where(status: "published").limit(@limit)
  end

  def cached_top_views
    cache_key = "analytics:top_views:#{@period}:#{@user_id}:#{@category_id}:#{@limit}"

    Rails.cache.fetch(cache_key, expires_in: cache_expiry) do
      top_views.to_a
    end
  end

  def cached_top_likes
    cache_key = "analytics:top_likes:#{@period}:#{@user_id}:#{@category_id}:#{@limit}"

    Rails.cache.fetch(cache_key, expires_in: cache_expiry) do
      top_likes.to_a
    end
  end

  def analytics_summary
    {
      total_blogs: Blog.published.count,
      total_views: Blog.published.sum(:views_count),
      total_likes: Blog.published.joins("LEFT JOIN votes ON blogs.id = votes.votable_id AND votes.votable_type = 'Blog'").count,
      top_blog: Blog.published.order(views_count: :desc).first,
      period: @period,
      generated_at: Time.current
    }
  end

  def invalidate_cache!
    # Invalidate all analytics cache when new views/likes are added
    Rails.cache.delete_matched("analytics:*")
  end

  private

  def cache_expiry
    case @period
    when "day"
      1.hour
    when "week"
      6.hours
    when "month"
      1.day
    when "year"
      1.week
    else
      1.hour
    end
  end
end
