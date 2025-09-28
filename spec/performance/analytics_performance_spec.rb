require 'rails_helper'

RSpec.describe "Analytics Performance Tests", type: :model do
  describe "AnalyticsService performance with large datasets" do
    let!(:users) { create_list(:user, 500) }
    let!(:categories) { create_list(:category, 10) }
    let!(:blogs) { create_list(:blog, 100, category: categories.sample) }

    before do
      puts "Setting up analytics performance test data..."

      # Create 50,000 blog views across all blogs
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

      # Create votes for blogs
      blogs.each do |blog|
        vote_count = rand(10..100)
        vote_count.times do
          user = users.sample
          blog.liked_by(user)
        end
      end

      puts "Created analytics test data with #{BlogView.count} views and #{ActiveRecord::Base.connection.execute('SELECT COUNT(*) FROM votes').first[0]} votes"
    end

    describe "top views analytics" do
      it "efficiently gets top blogs by views for day period" do
        service = AnalyticsService.new(period: "day", limit: 20)

        expect {
          service.cached_top_views
        }.to complete_within(2.seconds)

        top_views = service.cached_top_views
        expect(top_views.length).to be <= 20
      end

      it "efficiently gets top blogs by views for week period" do
        service = AnalyticsService.new(period: "week", limit: 20)

        expect {
          service.cached_top_views
        }.to complete_within(2.seconds)

        top_views = service.cached_top_views
        expect(top_views.length).to be <= 20
      end

      it "efficiently gets top blogs by views for month period" do
        service = AnalyticsService.new(period: "month", limit: 20)

        expect {
          service.cached_top_views
        }.to complete_within(2.seconds)

        top_views = service.cached_top_views
        expect(top_views.length).to be <= 20
      end

      it "efficiently gets top blogs by views for year period" do
        service = AnalyticsService.new(period: "year", limit: 20)

        expect {
          service.cached_top_views
        }.to complete_within(2.seconds)

        top_views = service.cached_top_views
        expect(top_views.length).to be <= 20
      end

      it "efficiently filters top views by category" do
        category = categories.first
        service = AnalyticsService.new(period: "week", category_id: category.id, limit: 20)

        expect {
          service.cached_top_views
        }.to complete_within(2.seconds)

        top_views = service.cached_top_views
        expect(top_views.length).to be <= 20
        # All returned blogs should belong to the specified category
        top_views.each do |blog|
          expect(blog.category_id).to eq(category.id)
        end
      end

      it "efficiently filters top views by user" do
        user = users.first
        service = AnalyticsService.new(period: "week", user_id: user.id, limit: 20)

        expect {
          service.cached_top_views
        }.to complete_within(2.seconds)

        top_views = service.cached_top_views
        expect(top_views.length).to be <= 20
      end
    end

    describe "top likes analytics" do
      it "efficiently gets top blogs by likes for day period" do
        service = AnalyticsService.new(period: "day", limit: 20)

        expect {
          service.cached_top_likes
        }.to complete_within(2.seconds)

        top_likes = service.cached_top_likes
        expect(top_likes.length).to be <= 20
      end

      it "efficiently gets top blogs by likes for week period" do
        service = AnalyticsService.new(period: "week", limit: 20)

        expect {
          service.cached_top_likes
        }.to complete_within(2.seconds)

        top_likes = service.cached_top_likes
        expect(top_likes.length).to be <= 20
      end

      it "efficiently gets top blogs by likes for month period" do
        service = AnalyticsService.new(period: "month", limit: 20)

        expect {
          service.cached_top_likes
        }.to complete_within(2.seconds)

        top_likes = service.cached_top_likes
        expect(top_likes.length).to be <= 20
      end

      it "efficiently gets top blogs by likes for year period" do
        service = AnalyticsService.new(period: "year", limit: 20)

        expect {
          service.cached_top_likes
        }.to complete_within(2.seconds)

        top_likes = service.cached_top_likes
        expect(top_likes.length).to be <= 20
      end

      it "efficiently filters top likes by category" do
        category = categories.first
        service = AnalyticsService.new(period: "week", category_id: category.id, limit: 20)

        expect {
          service.cached_top_likes
        }.to complete_within(2.seconds)

        top_likes = service.cached_top_likes
        expect(top_likes.length).to be <= 20
        # All returned blogs should belong to the specified category
        top_likes.each do |blog|
          expect(blog.category_id).to eq(category.id)
        end
      end
    end

    describe "analytics summary" do
      it "efficiently generates analytics summary" do
        service = AnalyticsService.new(period: "week", limit: 10)

        expect {
          service.analytics_summary
        }.to complete_within(3.seconds)

        summary = service.analytics_summary
        expect(summary).to be_a(Hash)
        expect(summary.keys).to include(:top_views, :top_likes, :total_blogs, :total_views, :total_likes)
      end

      it "efficiently generates analytics summary for different periods" do
        periods = %w[day week month year]

        periods.each do |period|
          service = AnalyticsService.new(period: period, limit: 10)

          expect {
            service.analytics_summary
          }.to complete_within(3.seconds)

          summary = service.analytics_summary
          expect(summary).to be_a(Hash)
        end
      end
    end

    describe "caching performance" do
      it "demonstrates caching effectiveness" do
        service = AnalyticsService.new(period: "week", limit: 20)

        # First call - should be slower (cache miss)
        start_time = Time.current
        service.cached_top_views
        first_call_time = Time.current - start_time

        # Second call - should be faster (cache hit)
        start_time = Time.current
        service.cached_top_views
        second_call_time = Time.current - start_time

        # Cache hit should be significantly faster
        expect(second_call_time).to be < (first_call_time * 0.5)
      end

      it "handles concurrent requests efficiently" do
        service = AnalyticsService.new(period: "week", limit: 20)

        # Simulate concurrent requests
        threads = []
        results = []

        5.times do
          threads << Thread.new do
            start_time = Time.current
            result = service.cached_top_views
            end_time = Time.current
            results << { result: result, time: end_time - start_time }
          end
        end

        threads.each(&:join)

        # All requests should complete within reasonable time
        results.each do |result|
          expect(result[:time]).to be < 3.seconds
          expect(result[:result]).to be_an(Array)
        end
      end
    end

    describe "memory usage optimization" do
      it "does not load excessive data into memory" do
        service = AnalyticsService.new(period: "week", limit: 50)

        # Monitor memory usage
        initial_memory = `ps -o rss= -p #{Process.pid}`.to_i

        service.cached_top_views

        final_memory = `ps -o rss= -p #{Process.pid}`.to_i
        memory_increase = final_memory - initial_memory

        # Memory increase should be reasonable (less than 50MB)
        expect(memory_increase).to be < 50_000 # KB
      end

      it "efficiently handles large limit values" do
        service = AnalyticsService.new(period: "week", limit: 1000)

        expect {
          service.cached_top_views
        }.to complete_within(5.seconds)

        top_views = service.cached_top_views
        expect(top_views.length).to be <= 1000
      end
    end
  end

  describe "Edge cases and stress tests" do
    it "handles empty datasets gracefully" do
      # Clear all data
      BlogView.delete_all
      Vote.delete_all
      Blog.update_all(views_count: 0)

      service = AnalyticsService.new(period: "week", limit: 20)

      expect {
        service.cached_top_views
      }.to complete_within(1.second)

      top_views = service.cached_top_views
      expect(top_views).to be_empty
    end

    it "handles very recent data efficiently" do
      # Create views only from the last hour
      recent_blog = create(:blog)
      recent_users = create_list(:user, 10)

      recent_users.each do |user|
        create(:blog_view, blog: recent_blog, user: user, viewed_at: rand(1.hour).seconds.ago)
      end

      service = AnalyticsService.new(period: "day", limit: 20)

      expect {
        service.cached_top_views
      }.to complete_within(1.second)

      top_views = service.cached_top_views
      expect(top_views).to include(recent_blog)
    end

    it "handles very old data efficiently" do
      # Create views only from a year ago
      old_blog = create(:blog)
      old_users = create_list(:user, 10)

      old_users.each do |user|
        create(:blog_view, blog: old_blog, user: user, viewed_at: 1.year.ago + rand(1.day).seconds)
      end

      service = AnalyticsService.new(period: "year", limit: 20)

      expect {
        service.cached_top_views
      }.to complete_within(1.second)

      top_views = service.cached_top_views
      expect(top_views).to include(old_blog)
    end
  end
end
