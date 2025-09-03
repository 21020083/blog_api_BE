class Api::V1::CommentsController < ApplicationController
  before_action :set_blog
  before_action :set_comment, only: [:destroy]

  # GET /blogs/:blog_id/comments
  def index
    top_comments = @blog.comments.where(parent_comment_id: nil)
    render json: top_comments.map { |c| comment_with_replies(c) }
  end

  # POST /blogs/:blog_id/comments
  def create
    comment = @blog.comments.new(comment_params)
    comment.user = current_user 

    if comment.save
      render json: comment_with_replies(comment), status: :created
    else
      render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /blogs/:blog_id/comments/:id
  def destroy
    if @comment.user == current_user
      @comment.destroy
      head :no_content
    else
      render json: { error: "Not authorized" }, status: :forbidden
    end
  end

  private

  def set_blog
    @blog = Blog.find(params[:blog_id])
  end

  def set_comment
    @comment = @blog.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:comment, :parent_comment_id)
  end

  def comment_with_replies(comment)
    {
      id: comment.id,
      comment: comment.comment,
      user: { id: comment.user.id, name: comment.user.name },
      replies: comment.replies.map { |r| comment_with_replies(r) }
    }
  end
end
