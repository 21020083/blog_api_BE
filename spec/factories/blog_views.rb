FactoryBot.define do
  factory :blog_view do
    blog
    user
    viewed_at { Time.current }

    trait :anonymous do
      user { nil }
    end

    trait :recent do
      viewed_at { 1.hour.ago }
    end

    trait :old do
      viewed_at { 1.week.ago }
    end

    trait :today do
      viewed_at { Time.current.beginning_of_day + rand(24.hours) }
    end

    trait :this_week do
      viewed_at { Time.current.beginning_of_week + rand(7.days) }
    end

    trait :this_month do
      viewed_at { Time.current.beginning_of_month + rand(30.days) }
    end
  end
end
