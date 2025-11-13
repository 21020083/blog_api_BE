FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:name) { |n| "User #{n}" }
    role { :user }
    jti { SecureRandom.uuid }

    trait :admin do
      role { :admin }
    end

    trait :with_blogs do
      transient do
        blogs_count { 5 }
      end

      after(:create) do |user, evaluator|
        create_list(:blog, evaluator.blogs_count, user: user)
      end
    end

    trait :with_comments do
      transient do
        comments_count { 10 }
      end

      after(:create) do |user, evaluator|
        create_list(:comment, evaluator.comments_count, user: user)
      end
    end

    trait :with_bookmarks do
      transient do
        bookmarks_count { 5 }
      end

      after(:create) do |user, evaluator|
        create_list(:bookmark, evaluator.bookmarks_count, user: user)
      end
    end
  end
end
