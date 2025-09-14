class CommentNotifier < ApplicationNotifier
  deliver_by :database

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :comment_email
  end

  required_param :comment

  recipients do
    params[:comment].blog.user
  end

  def message
    comment = params[:comment]
    blog = comment.blog
    user = comment.user
    "#{user.name} đã bình luận vào blog: #{blog.title.truncate(14)}"
  end

  def url
    blog_path(params[:comment].blog_id)
  end
end

