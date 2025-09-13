class BookmarkNotificationNotifier < Noticed::Event
  deliver_by :email, mailer: "UserMailer", method: :bookmark_notification

  required_param :bookmark

  def message
    "User #{params[:bookmark].user.name} đã bookmark blog của bạn: #{params[:bookmark].blog.title}"
  end

  def url
    Rails.application.routes.url_helpers.blog_url(params[:bookmark].blog)
  end
end
