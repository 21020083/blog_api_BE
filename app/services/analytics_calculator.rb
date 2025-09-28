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
      top_likes: calculate_top_likes,
      summary: calculate_summary
    }
  end

  private

  def calculate_top_views
    range = period_range

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
          period_views_count: blog.period_views_count,
          user_name: blog.user_name
        }
      end

    # Return empty array instead of nil if no data
    results.present? ? results : []
  end

  def calculate_top_likes
    range = period_range

    query = Blog.joins("LEFT JOIN votes ON blogs.id = votes.votable_id AND votes.votable_type = 'Blog'")
                .where(votes: { created_at: range })
                .where(status: :published)

    query = query.where("votes.voter_id = ?", @user_id) if @user_id.present?
    query = query.where(category_id: @category_id) if @category_id.present?

    results = query
      .select("blogs.id, blogs.title, blogs.views_count, users.name as user_name, COUNT(votes.id) as period_likes_count")
      .joins(:user)
      .group("blogs.id, blogs.title, blogs.views_count, users.name")
      .order("period_likes_count DESC")
      .limit(@limit)
      .map do |blog|
        {
          blog_id: blog.id,
          title: blog.title,
          views_count: blog.views_count,
          period_likes_count: blog.period_likes_count,
          user_name: blog.user_name
        }
      end

    # Return empty array instead of nil if no data
    results.present? ? results : []
  end

  def calculate_summary
    range = period_range

    # Total blogs
    total_blogs = Blog.where(status: :published)
    total_blogs = total_blogs.where(category_id: @category_id) if @category_id.present?
    total_blogs_count = total_blogs.count

    # Total views
    total_views_count = Blog.where(status: :published).sum(:views_count)

    # Total likes
    total_likes_count = ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) FROM votes WHERE votable_type = 'Blog'"
    ).first[0]

    # Top blog by views
    top_blog = Blog.where(status: :published)
                   .order(views_count: :desc)
                   .first

    {
      total_blogs: total_blogs_count,
      total_views: total_views_count,
      total_likes: total_likes_count,
      top_blog: top_blog ? {
        id: top_blog.id,
        title: top_blog.title,
        views_count: top_blog.views_count,
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
