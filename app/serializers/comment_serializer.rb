class CommentSerializer
  include JSONAPI::Serializer
  attributes :id, :comment_text, :updated_at
  
  belongs_to :blog

end