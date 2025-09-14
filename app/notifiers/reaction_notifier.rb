# To deliver this notification:
#
# ReactionNotifier.with(record: @post, message: "New post").deliver(User.all)

class ReactionNotifier < ApplicationNotifier
  deliver_by :database

  deliver_by :email do |config|
    config.mailer = "UserMailer"
    config.method = :reaction_email
  end

  required_param :voter
  required_param :votable
  required_param :vote_flag

  recipients do
    params[:votable].user
  end

  def message
    action = params[:vote_flag] ? "liked" : "disliked"
    target =
      case params[:votable]
      when Blog then "your blog: #{params[:votable].title.truncate(20)}"
      when Comment then "your comment on #{params[:votable].blog.title.truncate(20)}"
      else params[:votable].class.name
      end
    "#{params[:voter].name} #{action} #{target}"
  end

end
