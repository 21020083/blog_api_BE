FactoryBot.define do
  factory :audit_log do
    user
    action { "create" }
    entity_type { "Blog" }
    entity_id { 1 }

    trait :create_action do
      action { "create" }
    end

    trait :update_action do
      action { "update" }
    end

    trait :destroy_action do
      action { "destroy" }
    end

    trait :for_blog do
      entity_type { "Blog" }
      entity_id { create(:blog).id }
    end

    trait :for_comment do
      entity_type { "Comment" }
      entity_id { create(:comment).id }
    end

    trait :for_user do
      entity_type { "User" }
      entity_id { create(:user).id }
    end

    trait :recent do
      created_at { 1.day.ago }
    end

    trait :old do
      created_at { 1.month.ago }
    end
  end
end
