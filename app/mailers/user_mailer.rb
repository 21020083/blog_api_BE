class UserMailer < ApplicationMailer
  def bookmark_notification
    @bookmark = params[:bookmark]
    mail(
      to: @bookmark.blog.user.email,
      subject: "New bookmark notification"
    )
  end

  def comment_email
    @recipient = params[:recipient]
    raw_comment = params[:comment]

    @comment_content = raw_comment.is_a?(Hash) ? raw_comment['comment_text'] : raw_comment.comment_text
    @blog = raw_comment.is_a?(Hash) ? Blog.friendly.find(raw_comment['blog_id']) : raw_comment.blog

    mail(to: @recipient.email, subject: "Có bình luận mới trên blog của bạn")
  end

  def reaction_email
    @votable    = params[:votable]
    @voter     = params[:voter]
    @vote_flag = params[:vote_flag]
  
    @owner = @votable.user
    action = @vote_flag ? "like" : "dislike"
    klass  = @votable.class.name
  
    mail(
      to: @owner.email,
      subject: "#{@voter.name} #{action} your #{klass.downcase}: #{@record.try(:title)&.truncate(20) || @record.try(:content)&.truncate(20)}"
    )
  end
  
end
