class SerializableBlog < JSONAPI::Serializable::Resource
  type :blogs

  attributes :title, :content

  belongs_to :user
  has_many :comments
end
