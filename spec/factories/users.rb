FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    name { Faker::Name.name }
    profile 'principal'
    association(:city)
    association(:state)
    association(:school)
    association(:institution)

    factory :local_admin do
      profile 'local_admin'
    end

    factory :state_admin do
      profile 'admin_state'
    end

    factory :city_admin do
      profile 'admin_city'
    end

    factory :admin do
      profile 'admin'
    end
  end
end
