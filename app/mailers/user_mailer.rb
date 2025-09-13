class UserMailer < ApplicationMailer
  def bookmark_notification(notification)
    @bookmark = notification.params[:bookmark]
    mail(
      to: notification.recipient.email,
      subject: "New bookmark notification",
      body: "User #{@bookmark.user.name} đã bookmark blog của bạn: #{@bookmark.blog.title}"
    )
  end
end
