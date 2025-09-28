FactoryBot.define do
  factory :blog do
    sequence(:title) { |n| "Blog Post #{n}: #{Faker::Lorem.sentence(word_count: 3)}" }
    content { Faker::Lorem.paragraphs(number: 5).join("\n\n") }
    user
    category
    status { :published }
    views_count { 0 }

    trait :published do
      status { :published }
    end

    trait :draft do
      status { :draft }
    end

    trait :with_tags do
      transient do
        tags_count { 3 }
      end

      after(:create) do |blog, evaluator|
        tags = create_list(:tag, evaluator.tags_count)
        blog.tags << tags
      end
    end

    trait :with_comments do
      transient do
        comments_count { 5 }
      end

      after(:create) do |blog, evaluator|
        create_list(:comment, evaluator.comments_count, blog: blog)
      end
    end

    trait :with_views do
      transient do
        views_count { 10 }
      end

      after(:create) do |blog, evaluator|
        evaluator.views_count.times do
          create(:blog_view, blog: blog, user: create(:user))
        end
        blog.update(views_count: evaluator.views_count)
      end
    end

    trait :with_bookmarks do
      transient do
        bookmarks_count { 3 }
      end

      after(:create) do |blog, evaluator|
        create_list(:bookmark, evaluator.bookmarks_count, blog: blog)
      end
    end

    trait :popular do
      views_count { 100 }
      after(:create) do |blog|
        100.times do
          create(:blog_view, blog: blog, user: create(:user))
        end
      end
    end
  end
end
