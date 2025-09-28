FactoryBot.define do
  factory :comment do
    comment_text { Faker::Lorem.paragraph }
    user
    blog

    trait :reply do
      parent_comment { create(:comment) }
    end
  end
end
