class CategorySerializer
  include JSONAPI::Serializer

  set_type :category
  attributes :name, :slug, :id  

  attribute :children do |category|
    category.children.map do |child|
      {
        id: child.id,
        name: child.name,
        slug: child.slug,
        children: child.children.map { |c| CategorySerializer.new(c).serializable_hash[:data]&.dig(:attributes) || {} }
      }
    end
  end
end
