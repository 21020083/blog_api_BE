class BlogsController < ApplicationController
  include VotableController
  include Authorizable

  before_action :authenticate_user!
  before_action :set_blog, only: [ :show, :update, :destroy ]
  before_action :set_user, only: [ :index, :create ]
  before_action -> { authorize_owner!(@blog) }, only: [ :update ]
  before_action -> { authorize_admin_owner!(@blog) }, only: [ :destroy ]

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
    @blog = Blog.by_id_or_slug(params[:id]).first
    render_error errors: "Blog not found", status: :not_found unless @blog
  end

  def blog_params
    params.require(:blog).permit(:title, :content, :status, :category_id)
  end

  def set_user
    @user = User.find_by(id: params[:user_id])
    render_error errors: "User not found", status: :not_found unless @user
  end
end
