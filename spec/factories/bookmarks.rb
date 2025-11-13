FactoryBot.define do
  factory :bookmark do
    user
    blog

    trait :recent do
      created_at { 1.day.ago }
    end

    trait :old do
      created_at { 1.month.ago }
    end
  end
end
