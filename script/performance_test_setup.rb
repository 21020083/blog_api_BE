#!/usr/bin/env ruby
# Script để setup test data và chạy performance tests

require_relative '../config/environment'

class PerformanceTestSetup
  def initialize
    @user_count = 100
    @blog_count = 1000
    @views_per_blog = 100
    @total_views = @blog_count * @views_per_blog
  end

  def run
    puts "🚀 Setting up performance test data..."
    puts "Users: #{@user_count}"
    puts "Blogs: #{@blog_count}"
    puts "Views per blog: #{@views_per_blog}"
    puts "Total views: #{@total_views}"
    puts

    setup_test_data
    run_performance_tests
    show_results
  end

  private

  def setup_test_data
    puts "📊 Creating test data..."

    # Create users
    puts "Creating #{@user_count} users..."
    users = []
    @user_count.times do |i|
      users << User.create!(
        email: "user#{i}@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "User#{i}",
        last_name: "Test",
        confirmed_at: Time.current
      )
    end

    # Create categories
    puts "Creating categories..."
    categories = []
    10.times do |i|
      categories << Category.create!(
        name: "Category #{i}",
        description: "Test category #{i}"
      )
    end

    # Create blogs
    puts "Creating #{@blog_count} blogs..."
    blogs = []
    @blog_count.times do |i|
      blogs << Blog.create!(
        title: "Test Blog #{i}",
        content: "This is test content for blog #{i}. " * 10,
        user: users.sample,
        category: categories.sample,
        status: 'published',
        created_at: rand(30.days.ago..Time.current)
      )
    end

    # Create blog views
    puts "Creating #{@total_views} blog views..."
    views_data = []

    blogs.each do |blog|
      @views_per_blog.times do |i|
        views_data << {
          blog_id: blog.id,
          user_id: users.sample.id,
          viewed_at: rand(30.days.ago..Time.current),
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end

    # Batch insert for performance
    BlogView.insert_all(views_data)

    puts "✅ Test data created successfully!"
    puts "Users: #{User.count}"
    puts "Blogs: #{Blog.count}"
    puts "Blog Views: #{BlogView.count}"
    puts
  end

  def run_performance_tests
    puts "🧪 Running performance tests..."

    # Test different periods
    periods = %w[day week month year]

    periods.each do |period|
      puts "\n--- Testing #{period.capitalize} Period ---"

      # Test without cache
      time_without_cache = Benchmark.measure do
        service = AnalyticsService.new(period: period, limit: 50)
        service.top_views
      end.real

      # Test with cache
      time_with_cache = Benchmark.measure do
        service = AnalyticsService.new(period: period, limit: 50)
        service.cached_top_views
      end.real

      puts "Without cache: #{time_without_cache.round(3)}s"
      puts "With cache: #{time_with_cache.round(3)}s"
      puts "Cache improvement: #{((time_without_cache - time_with_cache) / time_without_cache * 100).round(1)}%"
    end
  end

  def show_results
    puts "\n📈 Performance Summary:"
    puts "=" * 50

    # Database stats
    puts "Database Statistics:"
    puts "  Users: #{User.count}"
    puts "  Blogs: #{Blog.count}"
    puts "  Blog Views: #{BlogView.count}"
    puts "  Categories: #{Category.count}"
    puts

    # Query performance
    puts "Query Performance:"
    periods = %w[day week month year]

    periods.each do |period|
      service = AnalyticsService.new(period: period, limit: 10)

      # Count queries
      query_count = 0
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        query_count += 1
      end

      time = Benchmark.measure do
        service.cached_top_views
      end.real

      ActiveSupport::Notifications.unsubscribe("sql.active_record")

      puts "  #{period.capitalize}: #{time.round(3)}s (#{query_count} queries)"
    end

    puts "\n✅ Performance test completed!"
    puts "Run 'bundle exec rspec spec/performance/' for detailed tests"
  end
end

# Run the setup
if __FILE__ == $0
  PerformanceTestSetup.new.run
end
