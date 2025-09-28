FactoryBot.define do
  factory :blog do
    title { Faker::Lorem.sentence(word_count: 3) }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    user
    category
    status { :published }

    trait :published do
      status { :published }
    end

    trait :draft do
      status { :draft }
    end
  end
end
