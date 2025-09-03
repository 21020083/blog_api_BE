class Api::V1::BlogsController < ApplicationController
  before_action :set_user
  before_action :set_blog, only: [:show, :update, :destroy]

  # GET /api/v1/users/:user_id/blogs
  def index
    @blogs = @user.blogs.where(deleted_at: nil).order(created_at: :desc)
    render json: @blogs
  end

  # GET /api/v1/users/:user_id/blogs/:id
  def show
    render json: @blog
  end

  # POST /api/v1/users/:user_id/blogs
  def create
    @blog = @user.blogs.new(blog_params)
    if @blog.save
      render json: @blog, status: :created
    else
      render json: { errors: @blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/users/:user_id/blogs/:id
  def update
    unless @blog.user_id == current_user.id || current_user.admin?
      render json: { error: "Unauthorized" }, status: :forbidden
      return
    end

    if @blog.update(blog_params)
      render json: @blog
    else
      render json: { errors: @blog.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/users/:user_id/blogs/:id
  def destroy
    unless @blog.user_id == current_user.id || current_user.admin?
      render json: { error: "Unauthorized" }, status: :forbidden
      return
    end

    @blog.update(deleted_at: Time.current)
    render json: { message: "Blog soft-deleted" }
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_blog
    @blog = @user.blogs.find(params[:id])
  end

  def blog_params
    params.require(:blog).permit(:title, :slug, :content, :status, category_ids: [], tag_ids: [])
  end
end
