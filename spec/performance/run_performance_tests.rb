#!/usr/bin/env ruby

# Performance Test Runner
# This script runs performance tests with proper setup and reporting

require 'rails_helper'
require 'benchmark'

class PerformanceTestRunner
  def initialize
    @results = {}
    @start_time = Time.current
  end

  def run_all_tests
    puts "=" * 80
    puts "BLOG API PERFORMANCE TESTS"
    puts "=" * 80
    puts "Starting at: #{@start_time}"
    puts

    # Run different test suites
    run_blog_views_tests
    run_analytics_tests
    run_controller_tests

    # Generate report
    generate_report
  end

  private

  def run_blog_views_tests
    puts "Running Blog Views Performance Tests..."
    puts "-" * 50

    test_cases = [
      { name: "100,000 views - total views count", method: :test_total_views },
      { name: "100,000 views - unique views count", method: :test_unique_views },
      { name: "100,000 views - views in range", method: :test_views_in_range },
      { name: "100,000 views - top blogs by views", method: :test_top_blogs_by_views },
      { name: "100,000 views - daily aggregation", method: :test_daily_aggregation },
      { name: "100,000 views - weekly aggregation", method: :test_weekly_aggregation },
      { name: "100,000 views - monthly aggregation", method: :test_monthly_aggregation }
    ]

    test_cases.each do |test_case|
      run_test_case(test_case)
    end

    puts
  end

  def run_analytics_tests
    puts "Running Analytics Performance Tests..."
    puts "-" * 50

    test_cases = [
      { name: "Analytics - top views (day)", method: :test_analytics_top_views_day },
      { name: "Analytics - top views (week)", method: :test_analytics_top_views_week },
      { name: "Analytics - top views (month)", method: :test_analytics_top_views_month },
      { name: "Analytics - top likes (week)", method: :test_analytics_top_likes_week },
      { name: "Analytics - summary generation", method: :test_analytics_summary },
      { name: "Analytics - caching effectiveness", method: :test_analytics_caching }
    ]

    test_cases.each do |test_case|
      run_test_case(test_case)
    end

    puts
  end

  def run_controller_tests
    puts "Running Controller Performance Tests..."
    puts "-" * 50

    test_cases = [
      { name: "Controller - paginated blogs (20 per page)", method: :test_controller_paginated_blogs },
      { name: "Controller - filter by category", method: :test_controller_filter_category },
      { name: "Controller - filter by tags", method: :test_controller_filter_tags },
      { name: "Controller - complex filtering", method: :test_controller_complex_filtering },
      { name: "Controller - blog details with many views", method: :test_controller_blog_details },
      { name: "Controller - analytics endpoints", method: :test_controller_analytics }
    ]

    test_cases.each do |test_case|
      run_test_case(test_case)
    end

    puts
  end

  def run_test_case(test_case)
    start_time = Time.current

    begin
      result = send(test_case[:method])
      end_time = Time.current
      duration = end_time - start_time

      status = result ? "PASS" : "FAIL"
      puts "#{status} - #{test_case[:name]} (#{duration.round(3)}s)"

      @results[test_case[:name]] = {
        status: status,
        duration: duration,
        passed: result
      }
    rescue => e
      end_time = Time.current
      duration = end_time - start_time

      puts "ERROR - #{test_case[:name]} (#{duration.round(3)}s) - #{e.message}"

      @results[test_case[:name]] = {
        status: "ERROR",
        duration: duration,
        passed: false,
        error: e.message
      }
    end
  end

  # Test methods for blog views
  def test_total_views
    blog = create_test_blog_with_views(100000)

    start_time = Time.current
    views_count = blog.total_views
    end_time = Time.current

    duration = end_time - start_time
    duration < 0.1 && views_count == 100000
  end

  def test_unique_views
    blog = create_test_blog_with_views(100000)

    start_time = Time.current
    unique_count = blog.unique_views
    end_time = Time.current

    duration = end_time - start_time
    duration < 2.0 && unique_count > 0
  end

  def test_views_in_range
    blog = create_test_blog_with_views(100000)
    start_time = 1.month.ago
    end_time = Time.current

    start_test = Time.current
    views_in_range = blog.views_in_range(start_time, end_time)
    end_test = Time.current

    duration = end_test - start_test
    duration < 2.0 && views_in_range >= 0
  end

  def test_top_blogs_by_views
    create_test_blogs_with_views(50, 2000)
    range = 1.year.ago..Time.current

    start_time = Time.current
    top_blogs = Blog.top_by_views(range: range).limit(10).to_a
    end_time = Time.current

    duration = end_time - start_time
    duration < 5.0 && top_blogs.length <= 10
  end

  def test_daily_aggregation
    blog = create_test_blog_with_views(10000)

    start_time = Time.current
    daily_views = blog.blog_views.group("DATE(viewed_at)").count
    end_time = Time.current

    duration = end_time - start_time
    duration < 3.0 && daily_views.is_a?(Hash)
  end

  def test_weekly_aggregation
    blog = create_test_blog_with_views(10000)

    start_time = Time.current
    weekly_views = blog.blog_views.group("YEARWEEK(viewed_at)").count
    end_time = Time.current

    duration = end_time - start_time
    duration < 3.0 && weekly_views.is_a?(Hash)
  end

  def test_monthly_aggregation
    blog = create_test_blog_with_views(10000)

    start_time = Time.current
    monthly_views = blog.blog_views.group("DATE_FORMAT(viewed_at, '%Y-%m')").count
    end_time = Time.current

    duration = end_time - start_time
    duration < 3.0 && monthly_views.is_a?(Hash)
  end

  # Test methods for analytics
  def test_analytics_top_views_day
    create_test_analytics_data
    service = AnalyticsService.new(period: "day", limit: 20)

    start_time = Time.current
    top_views = service.cached_top_views
    end_time = Time.current

    duration = end_time - start_time
    duration < 2.0 && top_views.is_a?(Array)
  end

  def test_analytics_top_views_week
    create_test_analytics_data
    service = AnalyticsService.new(period: "week", limit: 20)

    start_time = Time.current
    top_views = service.cached_top_views
    end_time = Time.current

    duration = end_time - start_time
    duration < 2.0 && top_views.is_a?(Array)
  end

  def test_analytics_top_views_month
    create_test_analytics_data
    service = AnalyticsService.new(period: "month", limit: 20)

    start_time = Time.current
    top_views = service.cached_top_views
    end_time = Time.current

    duration = end_time - start_time
    duration < 2.0 && top_views.is_a?(Array)
  end

  def test_analytics_top_likes_week
    create_test_analytics_data
    service = AnalyticsService.new(period: "week", limit: 20)

    start_time = Time.current
    top_likes = service.cached_top_likes
    end_time = Time.current

    duration = end_time - start_time
    duration < 2.0 && top_likes.is_a?(Array)
  end

  def test_analytics_summary
    create_test_analytics_data
    service = AnalyticsService.new(period: "week", limit: 10)

    start_time = Time.current
    summary = service.analytics_summary
    end_time = Time.current

    duration = end_time - start_time
    duration < 3.0 && summary.is_a?(Hash)
  end

  def test_analytics_caching
    create_test_analytics_data
    service = AnalyticsService.new(period: "week", limit: 20)

    # First call
    start_time = Time.current
    service.cached_top_views
    first_duration = Time.current - start_time

    # Second call (should be faster due to caching)
    start_time = Time.current
    service.cached_top_views
    second_duration = Time.current - start_time

    second_duration < (first_duration * 0.5)
  end

  # Test methods for controllers
  def test_controller_paginated_blogs
    create_test_blogs(1000)

    start_time = Time.current
    get "/blogs", params: { page: 1, per_page: 20 }
    end_time = Time.current

    duration = end_time - start_time
    duration < 2.0 && response.status == 200
  end

  def test_controller_filter_category
    create_test_blogs(1000)
    category = Category.first

    start_time = Time.current
    get "/blogs", params: { category_id: category.id, per_page: 50 }
    end_time = Time.current

    duration = end_time - start_time
    duration < 2.0 && response.status == 200
  end

  def test_controller_filter_tags
    create_test_blogs(1000)
    tag = Tag.first

    start_time = Time.current
    get "/blogs", params: { tag_ids: [ tag.id ], per_page: 50 }
    end_time = Time.current

    duration = end_time - start_time
    duration < 2.0 && response.status == 200
  end

  def test_controller_complex_filtering
    create_test_blogs(1000)
    category = Category.first
    tag = Tag.first

    start_time = Time.current
    get "/blogs", params: {
      category_id: category.id,
      tag_ids: [ tag.id ],
      per_page: 20
    }
    end_time = Time.current

    duration = end_time - start_time
    duration < 3.0 && response.status == 200
  end

  def test_controller_blog_details
    blog = create_test_blog_with_views(5000)

    start_time = Time.current
    get "/blogs/#{blog.id}"
    end_time = Time.current

    duration = end_time - start_time
    duration < 1.0 && response.status == 200
  end

  def test_controller_analytics
    create_test_analytics_data

    start_time = Time.current
    get "/analytics/top_views", params: { period: "week", limit: 50 }
    end_time = Time.current

    duration = end_time - start_time
    duration < 3.0 && response.status == 200
  end

  # Helper methods
  def create_test_blog_with_views(views_count)
    blog = create(:blog)
    users = create_list(:user, 100)

    views_data = []
    views_count.times do |i|
      user = users[i % users.length]
      views_data << {
        blog_id: blog.id,
        user_id: user.id,
        viewed_at: rand(365.days).seconds.ago,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    BlogView.insert_all(views_data)
    blog.update!(views_count: views_count)
    blog
  end

  def create_test_blogs_with_views(blog_count, views_per_blog)
    blogs = create_list(:blog, blog_count)
    users = create_list(:user, 100)

    blogs.each do |blog|
      views_data = []
      views_per_blog.times do |i|
        user = users[i % users.length]
        views_data << {
          blog_id: blog.id,
          user_id: user.id,
          viewed_at: rand(365.days).seconds.ago,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      BlogView.insert_all(views_data)
      blog.update!(views_count: views_per_blog)
    end

    blogs
  end

  def create_test_blogs(count)
    categories = create_list(:category, 5)
    tags = create_list(:tag, 10)

    blogs = create_list(:blog, count, category: categories.sample)

    blogs.each do |blog|
      blog.tags << tags.sample(rand(1..3))
    end

    blogs
  end

  def create_test_analytics_data
    users = create_list(:user, 100)
    categories = create_list(:category, 5)
    blogs = create_list(:blog, 50, category: categories.sample)

    # Create views
    blogs.each do |blog|
      views_count = rand(100..1000)
      views_data = []

      views_count.times do
        user = users.sample
        views_data << {
          blog_id: blog.id,
          user_id: user.id,
          viewed_at: rand(365.days).seconds.ago,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      BlogView.insert_all(views_data) if views_data.any?
      blog.update!(views_count: views_count)
    end

    # Create votes
    blogs.each do |blog|
      vote_count = rand(10..100)
      vote_count.times do
        user = users.sample
        blog.liked_by(user)
      end
    end
  end

  def generate_report
    end_time = Time.current
    total_duration = end_time - @start_time

    puts "=" * 80
    puts "PERFORMANCE TEST REPORT"
    puts "=" * 80
    puts "Total execution time: #{total_duration.round(3)} seconds"
    puts

    # Group results by status
    passed = @results.select { |_, result| result[:passed] }
    failed = @results.select { |_, result| !result[:passed] }

    puts "SUMMARY:"
    puts "  Passed: #{passed.count}"
    puts "  Failed: #{failed.count}"
    puts "  Total:  #{@results.count}"
    puts

    if failed.any?
      puts "FAILED TESTS:"
      puts "-" * 50
      failed.each do |name, result|
        puts "  #{name}: #{result[:error] || 'Performance threshold exceeded'}"
      end
      puts
    end

    puts "PERFORMANCE METRICS:"
    puts "-" * 50
    @results.each do |name, result|
      status_icon = result[:passed] ? "✓" : "✗"
      puts "  #{status_icon} #{name}: #{result[:duration].round(3)}s"
    end

    puts
    puts "=" * 80
  end
end

# Run the performance tests
if __FILE__ == $0
  runner = PerformanceTestRunner.new
  runner.run_all_tests
end
