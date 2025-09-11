class BlogsController < ApplicationController
  include VotableController

  before_action :authenticate_user!
  before_action :set_blog, only: [ :show, :update, :destroy ]
  before_action :set_user, only: [ :index, :create ]
  before_action :is_owner?, only: [ :update, :destroy ]
  before_action :owner_or_admin?, only: [ :destroy ]

  skip_before_action :authenticate_user!, only: [ :index, :show ]


  def index
    blogs = @user.blogs.page(params[:page]).per(params[:per_page] || 10)
    meta = pagination_data(blogs)
    render_success resource: blogs, meta: meta
  end

  def show
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
    @blog = Blog.find_by(id: params[:id]) || Blog.find_by(slug: params[:id])
    render_error errors: "Blog not found", status: :not_found unless @blog
  end

  def is_owner?
    render_error errors: "not owner", status: :unauthorized unless current_user == @user
  end

  def owner_or_admin?
    render_error errors: "Unauthorized", status: :unauthorized unless current_user == @user || current_user.admin?
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :status)
  end

  def set_user
    @user = User.find_by(id: params[:user_id])
    render_error errors: "User not found", status: :not_found unless @user
  end
end
