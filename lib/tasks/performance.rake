namespace :performance do
  desc "Run all performance tests"
  task all: :environment do
    puts "Running all performance tests..."
    system("bundle exec rspec spec/performance/ --format documentation")
  end

  desc "Run blog views performance tests"
  task blog_views: :environment do
    puts "Running blog views performance tests..."
    system("bundle exec rspec spec/performance/blog_views_performance_spec.rb --format documentation")
  end

  desc "Run analytics performance tests"
  task analytics: :environment do
    puts "Running analytics performance tests..."
    system("bundle exec rspec spec/performance/analytics_performance_spec.rb --format documentation")
  end

  desc "Run controller performance tests"
  task controllers: :environment do
    puts "Running controller performance tests..."
    system("bundle exec rspec spec/performance/controller_performance_spec.rb --format documentation")
  end

  desc "Run performance tests with custom runner"
  task custom: :environment do
    puts "Running performance tests with custom runner..."
    system("bundle exec ruby spec/performance/run_performance_tests.rb")
  end

  desc "Setup performance test data"
  task setup_data: :environment do
    puts "Setting up performance test data..."

    # Clean up existing data first
    puts "Cleaning up existing test data..."
    Bookmark.delete_all
    Comment.delete_all
    BlogView.delete_all
    BlogTag.delete_all
    Blog.delete_all
    Tag.delete_all
    Category.delete_all
    AuditLog.delete_all
    User.delete_all
    puts "Existing data cleaned up."

    # Create test users
    users = []
    1000.times do |i|
      users << User.create!(
        email: "perf_user_#{i}@example.com",
        password: "password123",
        password_confirmation: "password123",
        name: "Performance User #{i}",
        jti: SecureRandom.uuid
      )
    end
    puts "Created #{users.count} users"

    # Create test categories
    categories = []
    10.times do |i|
      categories << Category.create!(name: "Performance Category #{i}")
    end
    puts "Created #{categories.count} categories"

    # Create test tags
    tags = []
    50.times do |i|
      tags << Tag.create!(name: "perf-tag-#{i}")
    end
    puts "Created #{tags.count} tags"

    # Create test blogs
    blogs = []
    1000.times do |i|
      blog = Blog.create!(
        title: "Performance Blog #{i}",
        content: "This is performance test content for blog #{i}. " * 10,
        user: users.sample,
        category: categories.sample,
        status: :published,
        views_count: 0
      )

      # Add random tags
      blog.tags << tags.sample(rand(1..5))
      blogs << blog
    end
    puts "Created #{blogs.count} blogs"

    # Create blog views
    puts "Creating blog views (this may take a while)..."
    total_views = 0

    blogs.each_with_index do |blog, blog_index|
      views_count = rand(50..500)
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
      total_views += views_count

      if (blog_index + 1) % 100 == 0
        puts "Created views for #{blog_index + 1}/#{blogs.count} blogs"
      end
    end

    puts "Created #{total_views} blog views"

     # Create votes
     puts "Creating votes..."
     total_votes = 0

     blogs.each_with_index do |blog, blog_index|
       vote_count = rand(10..100)

       vote_count.times do
         user = users.sample
         blog.liked_by(user)
       end
       total_votes += vote_count

       if (blog_index + 1) % 100 == 0
         puts "Created votes for #{blog_index + 1}/#{blogs.count} blogs"
       end
     end

    puts "Created #{total_votes} votes"

    # Create comments
    puts "Creating comments..."
    total_comments = 0

    blogs.each_with_index do |blog, blog_index|
      comment_count = rand(0..50)
      comment_count.times do
        Comment.create!(
          comment_text: "This is a performance test comment. " * 5,
          user: users.sample,
          blog: blog
        )
      end
      total_comments += comment_count

      if (blog_index + 1) % 100 == 0
        puts "Created comments for #{blog_index + 1}/#{blogs.count} blogs"
      end
    end

    puts "Created #{total_comments} comments"

    # Create bookmarks
    puts "Creating bookmarks..."
    total_bookmarks = 0

    blogs.each_with_index do |blog, blog_index|
      bookmark_count = rand(0..20)
      bookmark_count.times do
        Bookmark.create!(
          user: users.sample,
          blog: blog
        )
      end
      total_bookmarks += bookmark_count

      if (blog_index + 1) % 100 == 0
        puts "Created bookmarks for #{blog_index + 1}/#{blogs.count} blogs"
      end
    end

    puts "Created #{total_bookmarks} bookmarks"

    puts "\nPerformance test data setup complete!"
    puts "Summary:"
    puts "  Users: #{User.count}"
    puts "  Categories: #{Category.count}"
    puts "  Tags: #{Tag.count}"
    puts "  Blogs: #{Blog.count}"
    puts "  Blog Views: #{BlogView.count}"
    puts "  Votes: #{ActiveRecord::Base.connection.execute('SELECT COUNT(*) FROM votes').first[0]}"
    puts "  Comments: #{Comment.count}"
    puts "  Bookmarks: #{Bookmark.count}"
  end

  desc "Clean up performance test data"
  task cleanup: :environment do
    puts "Cleaning up performance test data..."

    # Delete in reverse order of dependencies
    Bookmark.delete_all
    Comment.delete_all
    ActiveRecord::Base.connection.execute("DELETE FROM votes")
    BlogView.delete_all
    BlogTag.delete_all
    Blog.delete_all
    Tag.delete_all
    Category.delete_all
    AuditLog.delete_all
    User.delete_all

    puts "Performance test data cleaned up!"
  end

  desc "Run performance benchmark"
  task benchmark: :environment do
    puts "Running performance benchmark..."

    require "benchmark"

    # Benchmark blog queries
    puts "\nBlog Query Benchmarks:"
    puts "-" * 50

    Benchmark.bm(30) do |x|
      x.report("Blog.all.count") { Blog.count }
      x.report("Blog.includes(:user).limit(100)") { Blog.includes(:user).limit(100).to_a }
      x.report("Blog.joins(:tags).distinct.count") { Blog.joins(:tags).distinct.count }
      x.report("Blog.where(status: :published).count") { Blog.where(status: :published).count }
      x.report("Blog.page(1).per(20)") { Blog.page(1).per(20).to_a }
    end

    # Benchmark blog views queries
    puts "\nBlog Views Query Benchmarks:"
    puts "-" * 50

    Benchmark.bm(30) do |x|
      x.report("BlogView.count") { BlogView.count }
      x.report("BlogView.group(:blog_id).count") { BlogView.group(:blog_id).count }
      x.report("BlogView.where(viewed_at: 1.week.ago..)") { BlogView.where("viewed_at >= ?", 1.week.ago).count }
      x.report("BlogView.group('DATE(viewed_at)').count") { BlogView.group("DATE(viewed_at)").count }
      x.report("BlogView.joins(:blog).count") { BlogView.joins(:blog).count }
    end

    # Benchmark analytics queries
    puts "\nAnalytics Query Benchmarks:"
    puts "-" * 50

    Benchmark.bm(30) do |x|
      x.report("Blog.top_by_views (week)") { Blog.top_by_views_in(period: "week").limit(10).to_a }
      x.report("Blog.top_by_likes (week)") { Blog.top_by_likes_in(period: "week").limit(10).to_a }
      x.report("AnalyticsService.new.summary") { AnalyticsService.new(period: "week").analytics_summary }
    end

    puts "\nBenchmark complete!"
  end
end
