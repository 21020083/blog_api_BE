class AnalyticsCalculator
  def initialize(period:, period_date:, user_id: nil, category_id: nil, limit: 50)
    @period = period
    @period_date = period_date
    @user_id = user_id
    @category_id = category_id
    @limit = limit
  end

  def calculate_all
    {
      top_views: calculate_top_views,
      summary: calculate_summary
    }
  end

  private

  def calculate_top_views
    range = period_range

    # Use real-time query with blog_views join for accurate period-specific data
    query = Blog.joins(:blog_views)
                .where(blog_views: { viewed_at: range })
                .where(status: :published)

    query = query.where(blog_views: { user_id: @user_id }) if @user_id.present?
    query = query.where(category_id: @category_id) if @category_id.present?

    results = query
      .select("blogs.id, blogs.title, blogs.views_count, users.name as user_name, COUNT(blog_views.id) as period_views_count")
      .joins(:user)
      .group("blogs.id, blogs.title, blogs.views_count, users.name")
      .order("period_views_count DESC")
      .limit(@limit)
      .map do |blog|
        {
          blog_id: blog.id,
          title: blog.title,
          views_count: blog.views_count,
          period_views_count: blog.period_views_count,  # Real period-specific count
          user_name: blog.user_name
        }
      end

    # Return empty array instead of nil if no data
    results.present? ? results : []
  end


  def calculate_summary
    range = period_range

    # Total blogs with views in period
    total_blogs_query = Blog.joins(:blog_views)
                            .where(blog_views: { viewed_at: range })
                            .where(status: :published)
    total_blogs_query = total_blogs_query.where(category_id: @category_id) if @category_id.present?
    total_blogs_count = total_blogs_query.distinct.count

    # Total views in period
    total_views_query = BlogView.joins(:blog)
                                .where(blog_views: { viewed_at: range })
                                .where(blogs: { status: :published })
    total_views_query = total_views_query.where(blogs: { category_id: @category_id }) if @category_id.present?
    total_views_count = total_views_query.count

    # Total likes in period - simplified (not needed for views-only)
    total_likes_count = 0

    # Top blog by views in period
    top_blog = Blog.joins(:blog_views)
                   .where(blog_views: { viewed_at: range })
                   .where(status: :published)
                   .group("blogs.id")
                   .order("COUNT(blog_views.id) DESC")
                   .first

    {
      total_blogs: total_blogs_count,
      total_views: total_views_count,
      top_blog: top_blog ? {
        id: top_blog.id,
        title: top_blog.title,
        views_count: top_blog.views_count,
        period_views_count: top_blog.blog_views.where(viewed_at: range).count,
        user_name: top_blog.user.name
      } : nil,
      period: @period,
      period_date: @period_date,
      calculated_at: Time.current
    }
  end

  def period_range
    case @period
    when "day"
      @period_date.beginning_of_day..@period_date.end_of_day
    when "week"
      @period_date.beginning_of_week..@period_date.end_of_week
    when "month"
      @period_date.beginning_of_month..@period_date.end_of_month
    when "year"
      @period_date.beginning_of_year..@period_date.end_of_year
    end
  end
end
