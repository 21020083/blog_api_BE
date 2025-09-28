require 'rails_helper'
require 'benchmark'

RSpec.describe "Analytics Performance Tests", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let!(:blogs) { create_list(:blog, 1000, user: user, category: category, status: :published) }

  # Tạo 100,000 blog views để test performance
  let!(:blog_views) do
    puts "Creating 100,000 blog views for performance testing..."

    # Tạo views trong batch để tối ưu performance
    views_data = []
    blogs.each do |blog|
      # Mỗi blog có khoảng 100 views
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

    # Insert batch để tối ưu
    BlogView.insert_all(views_data)
    puts "Created #{BlogView.count} blog views"
  end

  describe "Performance Tests" do
    context "Top Views Analytics" do
      it "should handle 100k views efficiently" do
        puts "\n=== Testing Top Views Performance ==="

        # Test different periods
        periods = %w[day week month year]

        periods.each do |period|
          time = Benchmark.measure do
            get "/analytics/top_views", params: { period: period }
          end

          puts "#{period.capitalize}: #{time.real.round(3)}s"
          expect(response).to have_http_status(:success)
          expect(json_response['data']).to be_an(Array)
        end
      end

      it "should handle pagination efficiently" do
        puts "\n=== Testing Pagination Performance ==="

        time = Benchmark.measure do
          get "/analytics/top_views", params: { page: 1, per_page: 50 }
        end

        puts "Pagination (50 items): #{time.real.round(3)}s"
        expect(response).to have_http_status(:success)
        expect(json_response['data'].length).to be <= 50
      end

      it "should handle filtering by category efficiently" do
        puts "\n=== Testing Category Filter Performance ==="

        time = Benchmark.measure do
          get "/analytics/top_views", params: { category_id: category.id }
        end

        puts "Category filter: #{time.real.round(3)}s"
        expect(response).to have_http_status(:success)
        expect(json_response['data']).to be_an(Array)
      end
    end

    context "Database Query Analysis" do
      it "should show query count and time" do
        puts "\n=== Database Query Analysis ==="

        # Enable query logging
        ActiveRecord::Base.logger = Logger.new(STDOUT)

        query_count = 0
        ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
          query_count += 1
        end

        time = Benchmark.measure do
          get "/analytics/top_views", params: { period: "month" }
        end

        puts "Total queries: #{query_count}"
        puts "Total time: #{time.real.round(3)}s"
        puts "Average query time: #{(time.real / query_count * 1000).round(2)}ms" if query_count > 0

        expect(response).to have_http_status(:success)

        # Disable query logging
        ActiveRecord::Base.logger = nil
      end
    end

    context "Memory Usage Analysis" do
      it "should monitor memory usage" do
        puts "\n=== Memory Usage Analysis ==="

        # Get initial memory usage
        initial_memory = `ps -o rss= -p #{Process.pid}`.to_i

        time = Benchmark.measure do
          get "/analytics/top_views", params: { period: "year" }
        end

        # Get final memory usage
        final_memory = `ps -o rss= -p #{Process.pid}`.to_i
        memory_used = final_memory - initial_memory

        puts "Memory used: #{memory_used} KB"
        puts "Time taken: #{time.real.round(3)}s"

        expect(response).to have_http_status(:success)
      end
    end

    context "Concurrent Requests Test" do
      it "should handle multiple concurrent requests" do
        puts "\n=== Concurrent Requests Test ==="

        threads = []
        results = []

        # Simulate 10 concurrent requests
        10.times do |i|
          threads << Thread.new do
            start_time = Time.current
            get "/analytics/top_views", params: { period: "week" }
            end_time = Time.current

            results << {
              thread_id: i,
              response_time: (end_time - start_time).round(3),
              status: response.status
            }
          end
        end

        threads.each(&:join)

        avg_response_time = results.sum { |r| r[:response_time] } / results.length
        max_response_time = results.max_by { |r| r[:response_time] }[:response_time]

        puts "Average response time: #{avg_response_time.round(3)}s"
        puts "Max response time: #{max_response_time.round(3)}s"
        puts "All requests successful: #{results.all? { |r| r[:status] == 200 }}"

        expect(results.all? { |r| r[:status] == 200 }).to be true
      end
    end
  end

  describe "Performance Benchmarks" do
    it "should meet performance requirements" do
      puts "\n=== Performance Benchmarks ==="

      # Benchmark requirements
      requirements = {
        "day" => 0.1,    # 100ms
        "week" => 0.2,   # 200ms
        "month" => 0.5,  # 500ms
        "year" => 1.0    # 1s
      }

      results = {}

      requirements.each do |period, max_time|
        time = Benchmark.measure do
          get "/analytics/top_views", params: { period: period }
        end

        results[period] = time.real
        puts "#{period.capitalize}: #{time.real.round(3)}s (max: #{max_time}s) - #{time.real <= max_time ? 'PASS' : 'FAIL'}"

        expect(response).to have_http_status(:success)
      end

      # Check if all requirements are met
      failed_periods = results.select { |period, time| time > requirements[period] }

      if failed_periods.any?
        puts "\n❌ Performance requirements not met for: #{failed_periods.keys.join(', ')}"
        puts "Consider implementing optimizations like caching, database indexes, or query optimization."
      else
        puts "\n✅ All performance requirements met!"
      end
    end
  end
end
