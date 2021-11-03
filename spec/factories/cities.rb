FactoryGirl.define do
  factory :city do
    name { Faker::Address.city }
    association(:state)
  end
end
