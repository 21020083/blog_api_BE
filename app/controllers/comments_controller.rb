class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_blog, only: [:index, :create]
  before_action :set_comment, only: [:show, :update, :destroy, :create_reply]

  def index
    comments = @blog.comments.root_comments.all
    render_success resource: comments
  end

  def show
    render json: serialize_comment_tree(@comment)
  end

  def create
    comment = @blog.comments.new(comment_params)
    comment.user = current_user

    if comment.save
      render_success(resource: comment)
    else
      render_error(errors: comment.errors.full_messages)
    end
  end

  def create_reply
    parent_comment = @comment
    comment = parent_comment.replies.new(comment_params)
    comment.user = current_user
    comment.blog = parent_comment.blog

    if comment.save
      render_success(resource: comment)
    else
      render_error(errors: comment.errors.full_messages, status: :unprocessable_entity)
    end
  end

  def update
    if @comment.update(comment_params)
      render_success resource: @comment
    else
      render_error errors: @comment.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    head :no_content
  end

  private

  def set_blog
    @blog = Blog.find_by(id: params[:blog_id]) || Blog.find_by(slug: params[:blog_id])
    render_error errors: "Blog not found", status: :not_found unless @blog
  end

  def set_comment
    @comment = Comment.find_by(id: params[:id]) || Comment.find_by(id: params[:comment_id])
    render_error errors: "Comment not found hehe", status: :not_found unless @comment
  end

  def authorize_comment
    render_error errors: "Unauthorized", status: :unauthorized unless current_user == @comment.user || current_user.admin?
  end

  def comment_params
    params.require(:comment).permit(:comment_text, :parent_comment_id)
  end

  def serialize_comment_tree(comment)
    {
      id: comment.id,
      comment_text: comment.comment_text,
      user: {
        id: comment.user.id,
        name: comment.user.name
      },
      replies: comment.replies.map { |r| serialize_comment_tree(r) } # recursion
    }
  end
end
