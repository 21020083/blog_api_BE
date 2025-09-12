class TagsController < ApplicationController
  include Authorizable
  before_action :authenticate_user!
  before_action :set_tag, only: [ :show, :update, :destroy, :blogs ]
  before_action :authorize_admin!, only: [ :create, :update, :destroy ]

  def index
    tags = Tag.all
    render_success resource: tags
  end

  def show
    render_success resource: @tag
  end

  def create
    tag = Tag.new(tag_params)
    if tag.save
      render_success resource: tag
    else
      render_error(errors: tag.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def update
    if @tag.update(tag_params)
      render_success resource: @tag
    else
      render_error(errors: @tag.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def destroy
    if @tag.destroy
      render_success(status: :no_content)
    else
      render_error(errors: @tag.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def blogs
    blogs = @tag.blogs
    render_success resource: blogs
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
    render_error(errors: "Tag not found", status: :not_found) unless @tag
  end

  def tag_params
    params.require(:tag).permit(:name)
  end
end
