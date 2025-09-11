class CommentSerializer
  include JSONAPI::Serializer

  attributes :id, :comment_text, :blog_id, :parent_comment_id, :get_likes_count, :get_dislikes_count

  attribute :user do |comment|
    {
      id: comment.user.id,
      name: comment.user.name
    }
  end

  attribute :replies do |comment|
    comment.replies.map do |reply|
      {
        id: reply.id,
        comment_text: reply.comment_text,
        user: {
          id: reply.user.id,
          name: reply.user.name
        },
        replies: CommentSerializer.new(reply).serializable_hash[:data][:attributes][:replies]
      }
    end
  end
end
