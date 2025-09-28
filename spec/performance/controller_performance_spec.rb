require 'rails_helper'

RSpec.describe "Controller Performance Tests", type: :request do
  describe "BlogsController performance with large datasets" do
    let!(:users) { create_list(:user, 100) }
    let!(:categories) { create_list(:category, 5) }
    let!(:tags) { create_list(:tag, 20) }

    before do
      puts "Setting up controller performance test data..."

      # Create 1000 blogs with associations
      blogs = create_list(:blog, 1000, category: categories.sample)

      # Add tags to blogs
      blogs.each do |blog|
        blog.tags << tags.sample(rand(1..3))
      end

      # Create views for blogs
      blogs.each do |blog|
        views_count = rand(10..100)
        views_count.times do
          user = users.sample
          create(:blog_view, blog: blog, user: user, viewed_at: rand(365.days).seconds.ago)
        end
        blog.update!(views_count: views_count)
      end

      # Create comments for blogs
      blogs.each do |blog|
        comments_count = rand(0..20)
        create_list(:comment, comments_count, blog: blog, user: users.sample)
      end

      # Create bookmarks
      blogs.each do |blog|
        bookmarks_count = rand(0..10)
        create_list(:bookmark, bookmarks_count, blog: blog, user: users.sample)
      end

      puts "Created controller test data: #{Blog.count} blogs, #{BlogView.count} views, #{Comment.count} comments, #{Bookmark.count} bookmarks"
    end

    describe "GET /blogs performance" do
      it "efficiently returns paginated blogs" do
        expect {
          get "/blogs", params: { page: 1, per_page: 20 }
        }.to complete_within(2.seconds)

        expect_success_response
        expect(json_response['data'].length).to eq(20)
      end

      it "efficiently handles large page requests" do
        expect {
          get "/blogs", params: { page: 1, per_page: 100 }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data'].length).to eq(100)
      end

      it "efficiently filters blogs by category" do
        category = categories.first

        expect {
          get "/blogs", params: { category_id: category.id, per_page: 50 }
        }.to complete_within(2.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 50
      end

      it "efficiently filters blogs by user" do
        user = users.first

        expect {
          get "/blogs", params: { user_id: user.id, per_page: 50 }
        }.to complete_within(2.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 50
      end

      it "efficiently filters blogs by tags" do
        tag = tags.first

        expect {
          get "/blogs", params: { tag_ids: [ tag.id ], per_page: 50 }
        }.to complete_within(2.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 50
      end

      it "efficiently handles multiple tag filters" do
        selected_tags = tags.first(3)

        expect {
          get "/blogs", params: { tag_ids: selected_tags.pluck(:id), per_page: 50 }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 50
      end

      it "efficiently handles complex filtering" do
        category = categories.first
        tag = tags.first
        user = users.first

        expect {
          get "/blogs", params: {
            category_id: category.id,
            tag_ids: [ tag.id ],
            user_id: user.id,
            per_page: 20
          }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 20
      end
    end

    describe "GET /blogs/:id performance" do
      let(:blog) { Blog.first }

      it "efficiently returns blog details with many views" do
        # Add more views to make it realistic
        additional_views = rand(1000..5000)
        additional_views.times do
          user = users.sample
          create(:blog_view, blog: blog, user: user, viewed_at: rand(365.days).seconds.ago)
        end
        blog.update!(views_count: blog.views_count + additional_views)

        expect {
          get "/blogs/#{blog.id}"
        }.to complete_within(1.second)

        expect_success_response
        expect(json_response['data']['attributes']['views_count']).to eq(blog.views_count)
      end

      it "efficiently handles blog with many comments" do
        # Add more comments
        additional_comments = rand(100..500)
        create_list(:comment, additional_comments, blog: blog, user: users.sample)

        expect {
          get "/blogs/#{blog.id}"
        }.to complete_within(1.second)

        expect_success_response
      end

      it "efficiently handles blog with many bookmarks" do
        # Add more bookmarks
        additional_bookmarks = rand(50..200)
        create_list(:bookmark, additional_bookmarks, blog: blog, user: users.sample)

        expect {
          get "/blogs/#{blog.id}"
        }.to complete_within(1.second)

        expect_success_response
      end
    end

    describe "GET /blogs/:id/comments performance" do
      let(:blog) { Blog.first }

      before do
        # Create many comments for the blog
        create_list(:comment, 500, blog: blog, user: users.sample)
      end

      it "efficiently returns paginated comments" do
        expect {
          get "/blogs/#{blog.id}/comments", params: { page: 1, per_page: 20 }
        }.to complete_within(2.seconds)

        expect_success_response
        expect(json_response['data'].length).to eq(20)
      end

      it "efficiently handles large comment pages" do
        expect {
          get "/blogs/#{blog.id}/comments", params: { page: 1, per_page: 100 }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data'].length).to eq(100)
      end
    end

    describe "Analytics endpoints performance" do
      it "efficiently returns top views analytics" do
        expect {
          get "/analytics/top_views", params: { period: "week", limit: 50 }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 50
      end

      it "efficiently returns top likes analytics" do
        expect {
          get "/analytics/top_likes", params: { period: "week", limit: 50 }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 50
      end

      it "efficiently returns analytics summary" do
        expect {
          get "/analytics/summary", params: { period: "week", limit: 20 }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data']).to be_a(Hash)
      end

      it "efficiently filters analytics by category" do
        category = categories.first

        expect {
          get "/analytics/top_views", params: {
            period: "week",
            limit: 50,
            category_id: category.id
          }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 50
      end

      it "efficiently filters analytics by user" do
        user = users.first

        expect {
          get "/analytics/top_views", params: {
            period: "week",
            limit: 50,
            user_id: user.id
          }
        }.to complete_within(3.seconds)

        expect_success_response
        expect(json_response['data'].length).to be <= 50
      end
    end

    describe "Concurrent request handling" do
      it "handles multiple simultaneous blog requests" do
        blog_ids = Blog.limit(10).pluck(:id)

        threads = []
        results = []

        10.times do |i|
          threads << Thread.new do
            start_time = Time.current
            get "/blogs/#{blog_ids[i]}"
            end_time = Time.current
            results << {
              status: response.status,
              time: end_time - start_time,
              blog_id: blog_ids[i]
            }
          end
        end

        threads.each(&:join)

        # All requests should complete successfully and quickly
        results.each do |result|
          expect(result[:status]).to eq(200)
          expect(result[:time]).to be < 2.seconds
        end
      end

      it "handles multiple simultaneous analytics requests" do
        threads = []
        results = []

        5.times do
          threads << Thread.new do
            start_time = Time.current
            get "/analytics/top_views", params: { period: "week", limit: 20 }
            end_time = Time.current
            results << {
              status: response.status,
              time: end_time - start_time
            }
          end
        end

        threads.each(&:join)

        # All requests should complete successfully
        results.each do |result|
          expect(result[:status]).to eq(200)
          expect(result[:time]).to be < 5.seconds
        end
      end
    end

    describe "Memory usage optimization" do
      it "does not cause memory leaks with large datasets" do
        initial_memory = `ps -o rss= -p #{Process.pid}`.to_i

        # Make multiple requests
        10.times do
          get "/blogs", params: { page: 1, per_page: 50 }
          get "/analytics/top_views", params: { period: "week", limit: 20 }
        end

        final_memory = `ps -o rss= -p #{Process.pid}`.to_i
        memory_increase = final_memory - initial_memory

        # Memory increase should be reasonable (less than 100MB)
        expect(memory_increase).to be < 100_000 # KB
      end
    end
  end

  describe "Edge cases and stress tests" do
    it "handles requests with invalid parameters gracefully" do
      expect {
        get "/blogs", params: { page: -1, per_page: -1 }
      }.to complete_within(1.second)

      expect_success_response
    end

    it "handles requests with very large page numbers" do
      expect {
        get "/blogs", params: { page: 999999, per_page: 20 }
      }.to complete_within(1.second)

      expect_success_response
      expect(json_response['data']).to be_empty
    end

    it "handles requests with very large per_page values" do
      expect {
        get "/blogs", params: { page: 1, per_page: 10000 }
      }.to complete_within(5.seconds)

      expect_success_response
    end

    it "handles requests with non-existent category IDs" do
      expect {
        get "/blogs", params: { category_id: 999999 }
      }.to complete_within(1.second)

      expect_success_response
      expect(json_response['data']).to be_empty
    end

    it "handles requests with non-existent user IDs" do
      expect {
        get "/blogs", params: { user_id: 999999 }
      }.to complete_within(1.second)

      expect_success_response
      expect(json_response['data']).to be_empty
    end

    it "handles requests with non-existent tag IDs" do
      expect {
        get "/blogs", params: { tag_ids: [ 999999 ] }
      }.to complete_within(1.second)

      expect_success_response
      expect(json_response['data']).to be_empty
    end
  end
end
