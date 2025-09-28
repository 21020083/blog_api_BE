namespace :analytics do
  desc "Migrate existing analytics data to analytics_stats table"
  task migrate_data: :environment do
    puts "Starting analytics data migration..."

    # Get all existing periods we want to migrate
    periods = %w[day week month year]

    periods.each do |period|
      puts "\nMigrating #{period} data..."
      migrate_period_data(period)
    end

    puts "\nAnalytics data migration completed!"
  end

  desc "Generate analytics stats for current periods"
  task generate_current: :environment do
    puts "Generating current analytics stats..."

    periods = %w[day week month year]

    periods.each do |period|
      puts "Generating #{period} stats..."
      generate_period_stats(period)
    end

    puts "Current analytics stats generated!"
  end

  desc "Clean up old analytics stats"
  task cleanup: :environment do
    puts "Cleaning up old analytics stats..."

    # Keep only last 90 days
    cutoff_date = 90.days.ago
    old_stats = AnalyticsStat.where("calculated_at < ?", cutoff_date)

    puts "Found #{old_stats.count} old stats to delete"
    old_stats.delete_all

    puts "Cleanup completed!"
  end

  private

  def migrate_period_data(period)
    # Calculate period date based on current time
    period_date = case period
    when "day"
                    Date.current
    when "week"
                    Date.current.beginning_of_week.to_date
    when "month"
                    Date.current.beginning_of_month.to_date
    when "year"
                    Date.current.beginning_of_year.to_date
    end

    # Generate stats for all combinations
    generate_stats_for_period(period, period_date, nil, nil)  # All users, all categories

    # Generate stats for each category
    Category.find_each do |category|
      generate_stats_for_period(period, period_date, nil, category.id)
    end

    # Generate stats for each user (limit to active users)
    User.where("created_at > ?", 30.days.ago).find_each do |user|
      generate_stats_for_period(period, period_date, user.id, nil)
    end

    puts "  - Generated stats for #{period} period"
  end

  def generate_period_stats(period)
    period_date = case period
    when "day"
                    Date.current
    when "week"
                    Date.current.beginning_of_week.to_date
    when "month"
                    Date.current.beginning_of_month.to_date
    when "year"
                    Date.current.beginning_of_year.to_date
    end

    # Generate main stats (all users, all categories)
    generate_stats_for_period(period, period_date, nil, nil)
  end

  def generate_stats_for_period(period, period_date, user_id, category_id)
    # Check if stats already exist
    existing_stat = AnalyticsStat.find_by(
      period: period,
      period_date: period_date,
      user_id: user_id,
      category_id: category_id
    )

    if existing_stat&.fresh?
      puts "    - Stats already exist and fresh for #{period}/#{period_date}/#{user_id}/#{category_id}"
      return
    end

    begin
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
        puts "    - Updated stats for #{period}/#{period_date}/#{user_id}/#{category_id}"
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
        puts "    - Created stats for #{period}/#{period_date}/#{user_id}/#{category_id}"
      end

    rescue => e
      puts "    - Error generating stats for #{period}/#{period_date}/#{user_id}/#{category_id}: #{e.message}"
    end
  end
end
