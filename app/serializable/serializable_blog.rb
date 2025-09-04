class SerializableBlog < JSONAPI::Serializable::Resource
  type :blogs

  attributes :title, :content, :slug, :created_at, :updated_at
    

  attribute :date do
    @object.created_at
  end

  belongs_to :user

  has_many :comments do
    data do
      @object.comments
    end

  end

end
