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
    stat = get_analytics_stat
    return Blog.none unless stat

    # Return Blog relation directly from AnalyticsStat
    stat.top_views(limit: @limit)
  end

  def cached_top_views
    top_views
  end

  def invalidate_cache!
    # Invalidate analytics stats for current period
    period_date = get_period_date
    AnalyticsStat.where(
      period: @period,
      period_date: period_date,
      user_id: @user_id,
      category_id: @category_id
    ).delete_all
  end

  private

  def get_analytics_stat
    period_date = get_period_date
    AnalyticsStat.find_or_calculate(
      period: @period,
      period_date: period_date,
      user_id: @user_id,
      category_id: @category_id
    )
  end

  def get_period_date
    case @period
    when "day"
      Date.current
    when "week"
      Date.current.beginning_of_week.to_date
    when "month"
      Date.current.beginning_of_month.to_date
    when "year"
      Date.current.beginning_of_year.to_date
    else
      Date.current
    end
  end
end
