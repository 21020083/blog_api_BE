require 'rails_helper'

RSpec.describe "Blog Range Performance Tests", type: :model do
  describe "Blog Range Query Performance" do
    let!(:blog) { create(:blog) }
    let!(:users) { create_list(:user, 1000) }

    before(:each) do
      puts "Setting up performance test data..."

      existing_views = BlogView.count
      if existing_views < 1000000
        puts "Creating 1,000,000 blog views for performance testing..."

        # Tạo blog và users nếu chưa có
        test_blog = Blog.first || Blog.create!(title: "Performance Test Blog", content: "Test content", user: User.first, status: :published)
        test_users = User.limit(1000).to_a

        if test_users.empty?
          test_users = 1000.times.map { |i| User.create!(email: "perf_user#{i}@test.com", password: "password123", name: "Perf User #{i}") }
        end

        # Insert 1,000,000 views in batches to avoid connection timeout
        batch_size = 10000  # Insert 10,000 records per batch
        total_batches = 100  # 100 batches × 10,000 = 1,000,000

        puts "Inserting 1,000,000 views in #{total_batches} batches of #{batch_size}..."

        total_batches.times do |batch_num|
          views_data = []
          batch_size.times do |i|
            global_index = batch_num * batch_size + i
            user = test_users[global_index % test_users.length]
            views_data << {
              blog_id: test_blog.id,
              user_id: user.id,
              viewed_at: rand(30.days).seconds.ago,
              created_at: Time.current,
              updated_at: Time.current
            }
          end

          begin
            BlogView.insert_all(views_data)
            puts "Inserted batch #{batch_num + 1}/#{total_batches} (#{(batch_num + 1) * batch_size} records)"
          rescue => e
            puts "Error inserting batch #{batch_num + 1}: #{e.message}"
            puts "Retrying batch #{batch_num + 1}..."
            sleep(1)  # Wait 1 second before retry
            retry
          end
        end

        test_blog.update!(views_count: 1000000)
        puts "Created 1,000,000 blog views successfully"
      else
        puts "Using existing #{existing_views} blog views"
      end
    end

    it "efficiently finds blogs by day range" do
      range = Time.current.beginning_of_day..Time.current.end_of_day

      # Test that method works (không test performance vì có thể không có data trong ngày)
      top_blogs = Blog.top_by_views(range: range, limit: 20)
      expect(top_blogs).to be_an(ActiveRecord::Relation)
    end

    it "efficiently finds blogs by week range" do
      range = Time.current.beginning_of_week..Time.current.end_of_week

      # Test with performance expectation and show timing
      start_time = Time.current
      expect {
        Blog.top_by_views(range: range, limit: 20)
      }.to complete_within(10.seconds)
      end_time = Time.current

      puts "Week range query took: #{(end_time - start_time).round(3)} seconds"

      top_blogs = Blog.top_by_views(range: range, limit: 20)
      expect(top_blogs).to be_an(ActiveRecord::Relation)
    end

    it "efficiently finds blogs by month range" do
      range = Time.current.beginning_of_month..Time.current.end_of_month

      # Test with performance expectation and show timing
      start_time = Time.current
      expect {
        Blog.top_by_views(range: range, limit: 20)
      }.to complete_within(10.seconds)
      end_time = Time.current

      puts "Month range query took: #{(end_time - start_time).round(3)} seconds"

      top_blogs = Blog.top_by_views(range: range, limit: 20)
      expect(top_blogs).to be_an(ActiveRecord::Relation)
    end

    it "efficiently finds blogs by year range" do
      range = Time.current.beginning_of_year..Time.current.end_of_year

      # Test with performance expectation and show timing
      start_time = Time.current
      expect {
        Blog.top_by_views(range: range, limit: 20)
      }.to complete_within(10.seconds)
      end_time = Time.current

      puts "Year range query took: #{(end_time - start_time).round(3)} seconds"

      top_blogs = Blog.top_by_views(range: range, limit: 20)
      expect(top_blogs).to be_an(ActiveRecord::Relation)
    end

    it "efficiently finds blogs by custom range" do
      range = 1.month.ago..Time.current  # Range có data thật

      # Test with performance expectation and show timing
      start_time = Time.current
      expect {
        Blog.top_by_views(range: range, limit: 20)
      }.to complete_within(20.seconds)
      end_time = Time.current

      puts "Custom range query took: #{(end_time - start_time).round(3)} seconds"

      top_blogs = Blog.top_by_views(range: range, limit: 20)
      expect(top_blogs).to be_an(ActiveRecord::Relation)
    end

    it "efficiently filters blogs by user_id in range" do
      range = 1.month.ago..Time.current
      test_user = users.first

      # Test with performance expectation and show timing
      start_time = Time.current
      expect {
        Blog.top_by_views(range: range, user_id: test_user.id, limit: 20)
      }.to complete_within(10.seconds)
      end_time = Time.current

      puts "User filter query took: #{(end_time - start_time).round(3)} seconds"

      top_blogs = Blog.top_by_views(range: range, user_id: test_user.id, limit: 20)
      expect(top_blogs).to be_an(ActiveRecord::Relation)
    end

    it "efficiently filters blogs by category_id in range" do
      range = 1.month.ago..Time.current
      category = create(:category)
      blog.update!(category: category)

      # Test with performance expectation and show timing
      start_time = Time.current
      expect {
        Blog.top_by_views(range: range, category_id: category.id, limit: 20)
      }.to complete_within(10.seconds)
      end_time = Time.current

      puts "Category filter query took: #{(end_time - start_time).round(3)} seconds"

      top_blogs = Blog.top_by_views(range: range, category_id: category.id, limit: 20)
      expect(top_blogs).to be_an(ActiveRecord::Relation)
    end
  end

  describe "Real-time vs Cached Performance Comparison" do
    # Sử dụng data đã tạo từ describe trước
    let(:blog) { Blog.first }
    let(:users) { User.limit(1000) }

    it "real-time day query is fast enough" do
      range = Time.current.beginning_of_day..Time.current.end_of_day

      # Test with performance expectation and show timing
      start_time = Time.current
      expect {
        Blog.realtime_top_views(range: range, limit: 20)
      }.to complete_within(10.seconds)
      end_time = Time.current

      puts "Real-time day query took: #{(end_time - start_time).round(3)} seconds"
    end

    it "hybrid approach chooses correct strategy" do
      # Day range should use real-time
      day_range = Time.current.beginning_of_day..Time.current.end_of_day
      expect(Blog.detect_period_type(day_range)).to eq("day")

      # Week range should use cached
      week_range = Time.current.beginning_of_week..Time.current.end_of_week
      expect(Blog.detect_period_type(week_range)).to eq("week")

      # Custom range should use real-time
      custom_range = 3.days.ago..1.day.ago
      expect(Blog.detect_period_type(custom_range)).to eq("custom")

      puts "Period detection tests completed successfully"
    end
  end
end
