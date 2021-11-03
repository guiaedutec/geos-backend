FactoryGirl.define do
  factory :state do
    acronym { Faker::Address.state_abbr }
    name { Faker::Address.state }
    association(:region)
  end
end
