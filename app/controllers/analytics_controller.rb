class AnalyticsController < ApplicationController
  PERIODS = %w[day week month year].freeze

  def top_views
    render_top(:views)
  end

  def top_likes
    render_top(:likes)
  end

  private

  def render_top(metric)
    period      = params[:period].presence || "day"
    user_id     = params[:user_id]
    category_id = params[:category_id]
    unless PERIODS.include?(period)
      render_error(errors: ["Invalid period"], status: :bad_request) and return
    end

    method_name = "top_by_#{metric}_in"
    blogs = Blog.public_send(method_name, period: period, user_id: user_id, category_id: category_id)

    render_success(resource: blogs, status: :ok)
  end
end
