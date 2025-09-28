require 'rails_helper'

RSpec.describe "Blog Views Performance Tests", type: :model do
  describe "Large dataset performance tests" do
    let!(:blog) { create(:blog) }
    let!(:users) { create_list(:user, 1000) }

    describe "with 100,000 blog views" do
      before do
        puts "Creating 100,000 blog views..."
        start_time = Time.current

        # Create 100,000 blog views efficiently
        batch_size = 1000
        total_views = 100000

        (total_views / batch_size).times do |batch_index|
          views_data = []

          batch_size.times do |i|
            view_index = batch_index * batch_size + i
            user = users[view_index % users.length]

            views_data << {
              blog_id: blog.id,
              user_id: user.id,
              viewed_at: rand(365.days).seconds.ago,
              created_at: Time.current,
              updated_at: Time.current
            }
          end

          BlogView.insert_all(views_data)
          puts "Created batch #{batch_index + 1}/#{total_views / batch_size}" if (batch_index + 1) % 10 == 0
        end

        # Update blog views_count
        blog.update!(views_count: total_views)

        end_time = Time.current
        puts "Created 100,000 blog views in #{end_time - start_time} seconds"
      end

      it "efficiently counts total views" do
        expect {
          blog.total_views
        }.to complete_within(0.1.seconds)

        expect(blog.total_views).to eq(100000)
      end

      it "efficiently counts unique views" do
        expect {
          blog.unique_views
        }.to complete_within(2.seconds)

        # Should be close to 1000 unique users (some users might have multiple views)
        expect(blog.unique_views).to be_between(900, 1000)
      end

      it "efficiently counts views in a time range" do
        start_time = 1.month.ago
        end_time = Time.current

        expect {
          blog.views_in_range(start_time, end_time)
        }.to complete_within(2.seconds)

        views_in_range = blog.views_in_range(start_time, end_time)
        expect(views_in_range).to be > 0
        expect(views_in_range).to be <= 100000
      end

      it "efficiently counts unique views in a time range" do
        start_time = 1.month.ago
        end_time = Time.current

        expect {
          blog.unique_views_in_range(start_time, end_time)
        }.to complete_within(3.seconds)

        unique_views_in_range = blog.unique_views_in_range(start_time, end_time)
        expect(unique_views_in_range).to be > 0
        expect(unique_views_in_range).to be <= 1000
      end

      it "efficiently gets top blogs by views with large dataset" do
        # Create additional blogs with views
        other_blogs = create_list(:blog, 10)
        other_blogs.each_with_index do |other_blog, index|
          # Create fewer views for other blogs
          views_count = rand(1000..5000)
          views_count.times do
            user = users.sample
            create(:blog_view, blog: other_blog, user: user, viewed_at: rand(365.days).seconds.ago)
          end
          other_blog.update!(views_count: views_count)
        end

        range = 1.year.ago..Time.current

        expect {
          Blog.top_by_views(range: range).limit(10).to_a
        }.to complete_within(5.seconds)

        top_blogs = Blog.top_by_views(range: range).limit(10)
        expect(top_blogs.first).to eq(blog) # Our blog should be first
        expect(top_blogs.first.views_count).to eq(100000)
      end

      it "efficiently aggregates views by day" do
        expect {
          blog.blog_views
            .group("DATE(viewed_at)")
            .count
        }.to complete_within(3.seconds)

        daily_views = blog.blog_views.group("DATE(viewed_at)").count
        expect(daily_views.keys.length).to be > 0
        expect(daily_views.values.sum).to eq(100000)
      end

      it "efficiently aggregates views by week" do
        expect {
          blog.blog_views
            .group("YEARWEEK(viewed_at)")
            .count
        }.to complete_within(3.seconds)

        weekly_views = blog.blog_views.group("YEARWEEK(viewed_at)").count
        expect(weekly_views.keys.length).to be > 0
        expect(weekly_views.values.sum).to eq(100000)
      end

      it "efficiently aggregates views by month" do
        expect {
          blog.blog_views
            .group("DATE_FORMAT(viewed_at, '%Y-%m')")
            .count
        }.to complete_within(3.seconds)

        monthly_views = blog.blog_views.group("DATE_FORMAT(viewed_at, '%Y-%m')").count
        expect(monthly_views.keys.length).to be > 0
        expect(monthly_views.values.sum).to eq(100000)
      end

      it "efficiently finds most active users" do
        expect {
          blog.blog_views
            .where.not(user_id: nil)
            .group(:user_id)
            .order("COUNT(*) DESC")
            .limit(10)
            .count
        }.to complete_within(2.seconds)

        top_users = blog.blog_views
          .where.not(user_id: nil)
          .group(:user_id)
          .order("COUNT(*) DESC")
          .limit(10)
          .count

        expect(top_users.length).to be <= 10
        expect(top_users.values.sum).to be <= 100000
      end

      it "efficiently finds recent views" do
        expect {
          blog.blog_views
            .where("viewed_at >= ?", 1.week.ago)
            .count
        }.to complete_within(1.second)

        recent_views = blog.blog_views.where("viewed_at >= ?", 1.week.ago).count
        expect(recent_views).to be >= 0
        expect(recent_views).to be <= 100000
      end

      it "efficiently finds views by specific users" do
        test_users = users.first(10)

        expect {
          blog.blog_views
            .where(user_id: test_users.pluck(:id))
            .count
        }.to complete_within(1.second)

        user_views = blog.blog_views.where(user_id: test_users.pluck(:id)).count
        expect(user_views).to be >= 0
        expect(user_views).to be <= 100000
      end
    end

    describe "with multiple blogs and 100,000 total views" do
      let!(:blogs) { create_list(:blog, 50) }

      before do
        puts "Creating 100,000 views across 50 blogs..."
        start_time = Time.current

        # Distribute 100,000 views across 50 blogs
        views_per_blog = 100000 / 50

        blogs.each_with_index do |current_blog, blog_index|
          views_data = []

          views_per_blog.times do |i|
            user = users[i % users.length]
            views_data << {
              blog_id: current_blog.id,
              user_id: user.id,
              viewed_at: rand(365.days).seconds.ago,
              created_at: Time.current,
              updated_at: Time.current
            }
          end

          BlogView.insert_all(views_data)
          current_blog.update!(views_count: views_per_blog)

          puts "Created #{views_per_blog} views for blog #{blog_index + 1}/50" if (blog_index + 1) % 10 == 0
        end

        end_time = Time.current
        puts "Created 100,000 views across 50 blogs in #{end_time - start_time} seconds"
      end

      it "efficiently gets top blogs by views across multiple blogs" do
        range = 1.year.ago..Time.current

        expect {
          Blog.top_by_views(range: range).limit(20).to_a
        }.to complete_within(3.seconds)

        top_blogs = Blog.top_by_views(range: range).limit(20)
        expect(top_blogs.length).to eq(20)
        expect(top_blogs.first.views_count).to eq(2000) # 100000 / 50
      end

      it "efficiently gets total views across all blogs" do
        expect {
          BlogView.count
        }.to complete_within(1.second)

        expect(BlogView.count).to eq(100000)
      end

      it "efficiently gets unique users across all blogs" do
        expect {
          BlogView.where.not(user_id: nil).select(:user_id).distinct.count
        }.to complete_within(2.seconds)

        unique_users = BlogView.where.not(user_id: nil).select(:user_id).distinct.count
        expect(unique_users).to be_between(900, 1000)
      end

      it "efficiently gets views by category" do
        category = create(:category)
        category_blogs = blogs.first(10)
        category_blogs.each { |blog| blog.update!(category: category) }

        expect {
          BlogView.joins(:blog)
            .where(blogs: { category_id: category.id })
            .count
        }.to complete_within(1.second)

        category_views = BlogView.joins(:blog)
          .where(blogs: { category_id: category.id })
          .count

        expect(category_views).to eq(20000) # 10 blogs * 2000 views each
      end
    end

    describe "Database query optimization tests" do
      before do
        # Create a smaller dataset for query optimization tests
        create_list(:blog_view, 10000, blog: blog, user: users.sample)
        blog.update!(views_count: 10000)
      end

      it "uses proper indexes for views count queries" do
        # This test ensures our database indexes are working
        expect {
          blog.blog_views.where("viewed_at >= ?", 1.week.ago).count
        }.to complete_within(0.5.seconds)
      end

      it "uses proper indexes for user-based queries" do
        test_user = users.first

        expect {
          blog.blog_views.where(user_id: test_user.id).count
        }.to complete_within(0.5.seconds)
      end

      it "uses proper indexes for time range queries" do
        start_time = 1.month.ago
        end_time = Time.current

        expect {
          blog.blog_views.where(viewed_at: start_time..end_time).count
        }.to complete_within(0.5.seconds)
      end
    end
  end
end
