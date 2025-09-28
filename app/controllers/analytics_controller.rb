class AnalyticsController < ApplicationController
  PERIODS = %w[day week month year].freeze

  def top_views
    render_top(:views)
  end

  def top_likes
    render_top(:likes)
  end

  def summary
    period = params[:period].presence || "day"
    limit = params[:limit]&.to_i || 10

    unless PERIODS.include?(period)
      render_error(errors: [ "Invalid period" ], status: :bad_request) and return
    end

    service = AnalyticsService.new(period: period, limit: limit)
    summary_data = service.analytics_summary
    render_success(resource: summary_data, status: :ok)
  end

  private

  def render_top(metric)
    period = params[:period].presence || "day"
    user_id = params[:user_id]
    category_id = params[:category_id]
    limit = params[:limit]&.to_i || 50

    unless PERIODS.include?(period)
      render_error(errors: [ "Invalid period" ], status: :bad_request) and return
    end

    # Use optimized service
    service = AnalyticsService.new(
      period: period,
      user_id: user_id,
      category_id: category_id,
      limit: limit
    )

    blogs = case metric
    when :views
              service.cached_top_views
    when :likes
              service.cached_top_likes
    end

    render_success(resource: blogs, status: :ok)
  end
end
