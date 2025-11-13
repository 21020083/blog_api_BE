FactoryBot.define do
  factory :comment do
    comment_text { Faker::Lorem.paragraphs(number: 2).join("\n") }
    user
    blog

    trait :reply do
      parent_comment { create(:comment) }
    end

    trait :with_replies do
      transient do
        replies_count { 3 }
      end

      after(:create) do |comment, evaluator|
        create_list(:comment, evaluator.replies_count,
                   parent_comment: comment,
                   blog: comment.blog)
      end
    end

    trait :long_comment do
      comment_text { Faker::Lorem.paragraphs(number: 5).join("\n") }
    end
  end
end
