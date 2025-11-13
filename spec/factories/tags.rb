FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "tag-#{n}-#{Faker::Lorem.word}" }

    trait :with_blogs do
      transient do
        blogs_count { 5 }
      end

      after(:create) do |tag, evaluator|
        blogs = create_list(:blog, evaluator.blogs_count)
        tag.blogs << blogs
      end
    end

    trait :popular do
      after(:create) do |tag|
        20.times do
          blog = create(:blog)
          tag.blogs << blog
        end
      end
    end
  end
end
