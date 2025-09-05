class SerializableComment < JSONAPI::Serializable::Resource
  type :comments

  attributes :comment_text

  belongs_to :user
  belongs_to :blog
end