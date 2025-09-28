namespace :analytics do
  desc "Schedule analytics updates for all periods"
  task schedule_updates: :environment do
    puts "Scheduling analytics updates..."

    # Schedule updates for different periods
    periods = %w[day week month year]

    periods.each do |period|
      # Schedule for current period
      AnalyticsUpdateJob.perform_later(
        period: period,
        period_date: get_period_date(period)
      )

      puts "Scheduled #{period} analytics update"
    end

    puts "Analytics updates scheduled!"
  end

  desc "Schedule analytics updates for specific user"
  task :schedule_user_updates, [ :user_id ] => :environment do |t, args|
    user_id = args[:user_id]
    raise "User ID required" unless user_id

    puts "Scheduling analytics updates for user #{user_id}..."

    periods = %w[day week month year]

    periods.each do |period|
      AnalyticsUpdateJob.perform_later(
        period: period,
        period_date: get_period_date(period),
        user_id: user_id
      )

      puts "Scheduled #{period} analytics update for user #{user_id}"
    end
  end

  desc "Schedule analytics updates for specific category"
  task :schedule_category_updates, [ :category_id ] => :environment do |t, args|
    category_id = args[:category_id]
    raise "Category ID required" unless category_id

    puts "Scheduling analytics updates for category #{category_id}..."

    periods = %w[day week month year]

    periods.each do |period|
      AnalyticsUpdateJob.perform_later(
        period: period,
        period_date: get_period_date(period),
        category_id: category_id
      )

      puts "Scheduled #{period} analytics update for category #{category_id}"
    end
  end

  private

  def get_period_date(period)
    case period
    when "day"
      Date.current
    when "week"
      Date.current.beginning_of_week.to_date
    when "month"
      Date.current.beginning_of_month.to_date
    when "year"
      Date.current.beginning_of_year.to_date
    end
  end
end
