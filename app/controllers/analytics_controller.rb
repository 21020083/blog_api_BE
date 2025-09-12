class AnalyticsController < ApplicationController
  before_action :set_blog_info, only: [ :top_views, :top_likes ]

  def top_views
    blogs = case @period
    when "day"
              Blog.top_by_views_in_day(user_id: @user_id, category_id: @category_id)
    when "week"
              Blog.top_by_views_in_week(user_id: @user_id, category_id: @category_id)
    when "month"
              Blog.top_by_views_in_month(user_id: @user_id, category_id: @category_id)
    when "year"
              Blog.top_by_views_in_year(user_id: @user_id, category_id: @category_id)
    else
              render_error(errors: [ "Invalid period" ], status: :bad_request) and return
    end
    blogs
    render_success(resource: blogs, status: :ok)
  end

  def top_likes
    blogs = case @period
    when "day"
              Blog.top_by_likes_in_day(user_id: @user_id, category_id: @category_id)
    when "week"
              Blog.top_by_likes_in_week(user_id: @user_id, category_id: @category_id)
    when "month"
              Blog.top_by_likes_in_month(user_id: @user_id, category_id: @category_id)
    when "year"
              Blog.top_by_likes_in_year(user_id: @user_id, category_id: @category_id)
    else
              render_error(errors: [ "Invalid period" ], status: :bad_request) and return
    end
    blogs
    render_success(resource: blogs, status: :ok)
  end

  def set_blog_info
    @period = params[:period] || "day"
    @user_id = params[:user_id] ||
    @category_id = params[:category_id]
  end
end
