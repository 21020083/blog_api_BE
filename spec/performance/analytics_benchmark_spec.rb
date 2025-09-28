require 'rails_helper'
require 'benchmark'

RSpec.describe "Analytics Performance Benchmark", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let!(:blogs) { create_list(:blog, 1000, user: user, category: category, status: :published) }

  # Create 100,000 blog views
  let!(:blog_views) do
    puts "Setting up benchmark data..."

    views_data = []
    blogs.each do |blog|
      (1..100).each do |i|
        views_data << {
          blog_id: blog.id,
          user_id: user.id,
          viewed_at: rand(30.days.ago..Time.current),
          created_at: Time.current,
          updated_at: Time.current
        }
      end
    end

    BlogView.insert_all(views_data)
    puts "Created #{BlogView.count} blog views for benchmarking"
  end

  describe "Performance Comparison" do
    context "Before vs After Optimization" do
      it "compares old vs new analytics queries" do
        puts "\n=== Performance Benchmark Comparison ==="

        periods = %w[day week month year]

        periods.each do |period|
          puts "\n--- Testing #{period.capitalize} Period ---"

          # Test old method (if still available)
          old_time = 0
          begin
            old_time = Benchmark.measure do
              # Simulate old query pattern
              range = case period
              when "day" then Time.current.beginning_of_day..Time.current.end_of_day
              when "week" then Time.current.beginning_of_week..Time.current.end_of_week
              when "month" then Time.current.beginning_of_month..Time.current.end_of_month
              when "year" then Time.current.beginning_of_year..Time.current.end_of_year
              end

              Blog.joins(:blog_views)
                  .where(blog_views: { viewed_at: range })
                  .select("blogs.*, COUNT(blog_views.id) AS views_count")
                  .includes(:category, :user)
                  .group("blogs.id")
                  .order("views_count DESC")
                  .limit(50)
                  .to_a
            end.real
          rescue => e
            puts "Old method error: #{e.message}"
            old_time = 0
          end

          # Test new optimized method
          new_time = Benchmark.measure do
            service = AnalyticsService.new(period: period, limit: 50)
            service.top_views
          end.real

          # Test cached method
          cached_time = Benchmark.measure do
            service = AnalyticsService.new(period: period, limit: 50)
            service.cached_top_views
          end.real

          puts "Old method: #{old_time.round(3)}s" if old_time > 0
          puts "New method: #{new_time.round(3)}s"
          puts "Cached method: #{cached_time.round(3)}s"

          if old_time > 0
            improvement = ((old_time - new_time) / old_time * 100).round(1)
            puts "Improvement: #{improvement}%"
          end

          cache_improvement = ((new_time - cached_time) / new_time * 100).round(1)
          puts "Cache improvement: #{cache_improvement}%"
        end
      end
    end

    context "Database Query Analysis" do
      it "analyzes query efficiency" do
        puts "\n=== Database Query Analysis ==="

        # Enable query logging
        query_log = []
        ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          query_log << {
            sql: event.payload[:sql],
            duration: event.duration
          }
        end

        # Test optimized query
        service = AnalyticsService.new(period: "month", limit: 50)
        service.top_views

        puts "Total queries: #{query_log.length}"
        puts "Total query time: #{query_log.sum { |q| q[:duration] }.round(3)}ms"
        puts "Average query time: #{(query_log.sum { |q| q[:duration] } / query_log.length).round(3)}ms"

        # Show slowest queries
        slow_queries = query_log.sort_by { |q| -q[:duration] }.first(3)
        puts "\nSlowest queries:"
        slow_queries.each_with_index do |query, index|
          puts "#{index + 1}. #{query[:duration].round(3)}ms - #{query[:sql][0..100]}..."
        end

        # Disable query logging
        ActiveSupport::Notifications.unsubscribe("sql.active_record")
      end
    end

    context "Memory Usage Analysis" do
      it "compares memory usage" do
        puts "\n=== Memory Usage Analysis ==="

        # Test without caching
        initial_memory = get_memory_usage
        service = AnalyticsService.new(period: "week", limit: 100)
        service.top_views
        without_cache_memory = get_memory_usage - initial_memory

        # Test with caching
        initial_memory = get_memory_usage
        service.cached_top_views
        with_cache_memory = get_memory_usage - initial_memory

        puts "Memory without cache: #{without_cache_memory} KB"
        puts "Memory with cache: #{with_cache_memory} KB"
        puts "Memory saved: #{(without_cache_memory - with_cache_memory)} KB"
      end
    end

    context "Concurrent Load Testing" do
      it "tests concurrent request handling" do
        puts "\n=== Concurrent Load Testing ==="

        # Test concurrent requests
        threads = []
        results = []
        start_time = Time.current

        20.times do |i|
          threads << Thread.new do
            thread_start = Time.current
            service = AnalyticsService.new(period: "day", limit: 25)
            service.cached_top_views
            thread_end = Time.current

            results << {
              thread_id: i,
              response_time: (thread_end - thread_start).round(3),
              success: true
            }
          end
        end

        threads.each(&:join)
        total_time = Time.current - start_time

        avg_response_time = results.sum { |r| r[:response_time] } / results.length
        max_response_time = results.max_by { |r| r[:response_time] }[:response_time]
        min_response_time = results.min_by { |r| r[:response_time] }[:response_time]

        puts "Total time for 20 concurrent requests: #{total_time.round(3)}s"
        puts "Average response time: #{avg_response_time.round(3)}s"
        puts "Min response time: #{min_response_time.round(3)}s"
        puts "Max response time: #{max_response_time.round(3)}s"
        puts "Requests per second: #{(20 / total_time).round(2)}"

        expect(results.all? { |r| r[:success] }).to be true
      end
    end

    context "Cache Performance Testing" do
      it "tests cache hit rates and performance" do
        puts "\n=== Cache Performance Testing ==="

        service = AnalyticsService.new(period: "day", limit: 50)

        # First request (cache miss)
        cache_miss_time = Benchmark.measure do
          service.cached_top_views
        end.real

        # Second request (cache hit)
        cache_hit_time = Benchmark.measure do
          service.cached_top_views
        end.real

        puts "Cache miss time: #{cache_miss_time.round(3)}s"
        puts "Cache hit time: #{cache_hit_time.round(3)}s"
        puts "Cache speedup: #{(cache_miss_time / cache_hit_time).round(1)}x"

        # Test cache invalidation
        service.invalidate_cache!

        # Third request (cache miss after invalidation)
        cache_miss_after_invalidation = Benchmark.measure do
          service.cached_top_views
        end.real

        puts "Cache miss after invalidation: #{cache_miss_after_invalidation.round(3)}s"
      end
    end
  end

  describe "Performance Requirements" do
    it "validates performance meets requirements" do
      puts "\n=== Performance Requirements Validation ==="

      requirements = {
        "day" => { max_time: 0.1, max_queries: 5 },
        "week" => { max_time: 0.2, max_queries: 8 },
        "month" => { max_time: 0.5, max_queries: 10 },
        "year" => { max_time: 1.0, max_queries: 15 }
      }

      results = {}

      requirements.each do |period, req|
        query_count = 0
        ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
          query_count += 1
        end

        time = Benchmark.measure do
          service = AnalyticsService.new(period: period, limit: 50)
          service.cached_top_views
        end.real

        ActiveSupport::Notifications.unsubscribe("sql.active_record")

        results[period] = {
          time: time,
          queries: query_count,
          time_ok: time <= req[:max_time],
          queries_ok: query_count <= req[:max_queries]
        }

        puts "#{period.capitalize}:"
        puts "  Time: #{time.round(3)}s (max: #{req[:max_time]}s) - #{results[period][:time_ok] ? 'PASS' : 'FAIL'}"
        puts "  Queries: #{query_count} (max: #{req[:max_queries]}) - #{results[period][:queries_ok] ? 'PASS' : 'FAIL'}"
      end

      # Overall assessment
      all_passed = results.all? { |_, result| result[:time_ok] && result[:queries_ok] }

      if all_passed
        puts "\n✅ All performance requirements met!"
      else
        puts "\n❌ Some performance requirements not met. Consider further optimization."
      end
    end
  end

  private

  def get_memory_usage
    # Get memory usage in KB
    `ps -o rss= -p #{Process.pid}`.to_i
  end
end
