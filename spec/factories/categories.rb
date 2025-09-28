FactoryBot.define do
  factory :category do
    name { Faker::Lorem.word.capitalize }
  end
end
