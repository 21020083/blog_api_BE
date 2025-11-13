class AnalyticsUpdateJob < ApplicationJob
  queue_as :default

  def perform(period: "day", period_date: nil, user_id: nil, category_id: nil)
    period_date ||= case period
    when "day"
                      Date.current
    when "week"
                      Date.current.beginning_of_week.to_date
    when "month"
                      Date.current.beginning_of_month.to_date
    when "year"
                      Date.current.beginning_of_year.to_date
    end

    # Check if stats already exist and are fresh
    existing_stat = AnalyticsStat.find_by(
      period: period,
      period_date: period_date,
      user_id: user_id,
      category_id: category_id
    )

    return if existing_stat&.fresh?

    # Calculate new stats
    calculator = AnalyticsCalculator.new(
      period: period,
      period_date: period_date,
      user_id: user_id,
      category_id: category_id,
      limit: 50
    )

    stats_data = calculator.calculate_all

    # Create or update stats
    if existing_stat
      existing_stat.update!(
        top_views_data: stats_data[:top_views],
        top_likes_data: stats_data[:top_likes],
        summary_data: stats_data[:summary],
        total_blogs_count: stats_data[:summary][:total_blogs],
        total_views_count: stats_data[:summary][:total_views],
        total_likes_count: stats_data[:summary][:total_likes],
        calculated_at: Time.current
      )
    else
      AnalyticsStat.create!(
        period: period,
        period_date: period_date,
        user_id: user_id,
        category_id: category_id,
        top_views_data: stats_data[:top_views],
        top_likes_data: stats_data[:top_likes],
        summary_data: stats_data[:summary],
        total_blogs_count: stats_data[:summary][:total_blogs],
        total_views_count: stats_data[:summary][:total_views],
        total_likes_count: stats_data[:summary][:total_likes],
        calculated_at: Time.current
      )
    end

    Rails.logger.info "Updated analytics stats for #{period}/#{period_date}/#{user_id}/#{category_id}"
  end
end
