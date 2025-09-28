class BlogsController < ApplicationController
  include VotableController
  include Authorizable
  include ErrorHandler

  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_blog, only: [ :show, :update, :destroy ]
  before_action :set_category, :set_tags, :set_user, only: [ :index ]

  before_action -> { authorize_owner!(@blog) }, only: [ :update ]
  before_action -> { authorize_admin_owner!(@blog) }, only: [ :destroy ]

  def index
    blogs = Blog.all

    blogs = blogs.where(user_id: @user.id) if @user.present?

    blogs = blogs.where(category_id: @category.id) if @category.present?

    if @tags.present? && @tags.any?
      blogs = blogs.joins(:tags).where(tags: { id: @tags.pluck(:id) }).distinct
    elsif params[:tag_ids].present? && (!@tags.present? || @tags.empty?)
      blogs = Blog.none
    end

    blogs = blogs.page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(blogs)

    render_success resource: blogs, meta: meta
  end

  def show
    recent_views = @blog.blog_views.recent
    recent_views = recent_views.where(user_id: current_user.id) if current_user
    @blog.log_view(current_user) if recent_views.empty?

    render_success resource: @blog
  end

  def create
    current_user.blogs.create!(blog_params)
    render_success
  end

  def update
    @blog.update!(blog_params)
    render_success resource: @blog
  end

  def destroy
    @blog.destroy!
    render_success
  end

  private

  def set_blog
    @blog = Blog.friendly.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :status, :category_id, tag_ids: [])
  end

  def set_category
    @category = Category.friendly.find_by(id: params[:category_id])
  end

  def set_user
    @user = User.friendly.find_by(id: params[:user_id])
  end

  def set_tags
    ids = params[:tag_ids].is_a?(String) ? params[:tag_ids].split(",") : params[:tag_ids]
    @tags = Tag.where(id: ids) if ids.present?
  end
end
