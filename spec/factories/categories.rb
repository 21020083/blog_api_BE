FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "#{Faker::Lorem.word.capitalize} #{n}" }

    trait :with_parent do
      parent_category { create(:category) }
    end

    trait :with_blogs do
      transient do
        blogs_count { 5 }
      end

      after(:create) do |category, evaluator|
        create_list(:blog, evaluator.blogs_count, category: category)
      end
    end

    trait :with_children do
      transient do
        children_count { 3 }
      end

      after(:create) do |category, evaluator|
        create_list(:category, evaluator.children_count, parent_category: category)
      end
    end
  end
end
