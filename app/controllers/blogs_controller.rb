class BlogsController < ApplicationController
  include VotableController
  include Authorizable

  before_action :authenticate_user!, only: [ :update, :destroy, :create ]
  before_action :set_blog, only: [ :show, :update, :destroy ]
  before_action :set_category, :set_tag, only: [ :index ]
  before_action :set_user
  before_action -> { authorize_owner!(@blog) }, only: [ :update ]
  before_action -> { authorize_admin_owner!(@blog) }, only: [ :destroy ]


  def index
    blogs = Blog.all

    blogs = blogs.where(user_id: @user.id) if @user
    blogs = @category.blogs_from_leaf_descendants if @category
    blogs = blogs.joins(:tags).where(tags: { id: @tag.id }) if @tag

    blogs = blogs.page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(blogs)
    render_success resource: blogs, meta: meta
  end

  def show
    recent_views = @blog.blog_views.recent
    recent_views = recent_views.where(user_id: current_user.id) if current_user

    if recent_views.empty?
      @blog.blog_views.create(user: current_user)
    end
    render_success resource: @blog
  end

  def create
    @blog = @user.blogs.build(blog_params)
    if @blog.save
      render_success resource: @blog, status: :created
    else
      render_error errors: @blog.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    if @blog.update(blog_params)
      render_success resource: @blog
    else
      render_error errors: @blog.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    if @blog.destroy
      render_success
    else
      render_error errors: @blog.errors.full_messages, status: :unprocessable_entity
    end
  end

  private

  def set_blog
    @blog = Blog.friendly.find_by(id: params[:id])
    render_error(errors: "Blog not found", status: :not_found) unless @blog
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :status, :category_id, tag_ids: [])
  end

  def set_user
    @user = User.find_by(id: params[:user_id])
  end

  def set_category
    @category = Category.friendly.find_by(id: params[:category_id])
  end

  def set_tag
    @tag = Tag.find_by(id: params[:tag_id])
  end
end
