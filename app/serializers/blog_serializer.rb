class BlogSerializer
  include JSONAPI::Serializer
  attributes :id, :title, :content,
            :status, :slug, :created_at,
            :updated_at, :get_likes_count,
            :get_dislikes_count, :user_id, :views_count, :tag_ids

  attribute :root_comments do |object|
    object.comments.root_comments.map do |comment|
      {
        id: comment.id,
        comment_text: comment.comment_text,
        user_id: comment.user_id,
        get_likes_count: comment.get_likes_count,
        get_dislikes_count: comment.get_dislikes_count
      }
    end
  end

  attribute :category do |object|
    {
      id: object.category&.id,
      name: object.category&.name
    }
  end
end
