class BlogsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user, only: [ :update, :destroy ]
  before_action :set_blog, only: [ :show, :update, :destroy ]
  before_action :set_user, only: [ :index, :show ]

  def index
    blogs = @user.blogs.page(params[:page]).per(params[:per_page] || 10)

    meta = {
      total_pages: blogs.total_pages,
      current_page: blogs.current_page,
      per_page: blogs.limit_value,
      total_count: blogs.total_count
    }
    if blogs.empty?
      render_error message: "No blogs found", status: :not_found, data: @user.blogs.as_json
    else
      render_success data: BlogSerializer.new(blogs).serializable_hash[:data], meta: meta
    end
  end

  def show
    render_success data: BlogSerializer.new(@blog).serializable_hash[:data]
  end

  def create
    @blog = current_user.blogs.build(blog_params)
    if @blog.save
      render_success data: BlogSerializer.new(@blog).serializable_hash[:data], status: :created
    else
      render_error errors: @blog.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
    if @blog.update(blog_params)
      render_success data: BlogSerializer.new(@blog).serializable_hash[:data]
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
    @blog = Blog.find_by(id: params[:id])
    render_error message: "Blog not found", status: :not_found unless @blog
  end

  def authorize_user
    return if current_user == @blog.user || current_user.admin?

    render_error message: "Unauthorized", status: :unauthorized
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :status)
  end

  def set_user
    @user = User.find_by(id: params[:user_id]) || current_user
    render_error message: "User not found", status: :not_found unless @user
  end
end
