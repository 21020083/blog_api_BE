class BookmarkNotificationNotifier < Noticed::Event
  deliver_by :database

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :bookmark_notification
  end

  required_param :bookmark

  recipients do
    params[:bookmark].blog.user
  end

  def message
    "User #{params[:bookmark].user.name} đã bookmark blog của bạn: #{params[:bookmark].blog.title}"
  end

  def url
    blog_path(params[:bookmark].blog_id)
  end
end
