class AnalyticsController < ApplicationController
  PERIODS = %w[day week month year].freeze

  def top_views
    period = params[:period].presence || "day"
    user_id = params[:user_id]
    category_id = params[:category_id]
    limit = params[:limit]&.to_i || 50

    unless PERIODS.include?(period)
      render_error(errors: [ "Invalid period" ], status: :bad_request) and return
    end

    # Use the optimized service layer
    service = AnalyticsService.new(
      period: period,
      user_id: user_id,
      category_id: category_id,
      limit: limit
    )

    blogs = service.top_views
    render_success(resource: blogs, status: :ok, serializer: AnalyticsBlogSerializer)
  end


  def top_views_cached
    # Test with cache
    render_top
  end

  def top_views_simple
    # Simple query for all-time top blogs (using cached views_count)
    blogs = Blog.select("id, title, views_count, created_at, updated_at, user_id, category_id")
                .where(status: :published)
                .order(views_count: :desc)
                .limit(50)

    render_success(resource: blogs, status: :ok, serializer: AnalyticsBlogSerializer)
  end

  def summary
    period = params[:period].presence || "week"
    user_id = params[:user_id]
    category_id = params[:category_id]

    unless PERIODS.include?(period)
      render_error(errors: [ "Invalid period" ], status: :bad_request) and return
    end

    service = AnalyticsService.new(period: period, user_id: user_id, category_id: category_id)
    stat = service.send(:get_analytics_stat)

    if stat
      summary_data = {
        period: period,
        period_date: stat.period_date,
        total_blogs: stat.total_blogs_count,
        total_views: stat.total_views_count,
        total_likes: stat.total_likes_count,
        calculated_at: stat.calculated_at
      }
      render_success(resource: summary_data, status: :ok)
    else
      render_error(errors: [ "No analytics data found" ], status: :not_found)
    end
  end

  private

  def render_top
    period = params[:period].presence || "week"
    user_id = params[:user_id]
    category_id = params[:category_id]
    limit = params[:limit]&.to_i || 50

    unless PERIODS.include?(period)
      render_error(errors: [ "Invalid period" ], status: :bad_request) and return
    end

    service = AnalyticsService.new(
      period: period,
      user_id: user_id,
      category_id: category_id,
      limit: limit
    )

    blogs = service.cached_top_views

    render_success(resource: blogs, status: :ok, serializer: AnalyticsBlogSerializer)
  end
end
