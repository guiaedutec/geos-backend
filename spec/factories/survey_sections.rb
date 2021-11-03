FactoryGirl.define do
  factory :survey_section do
    name 'MyString'
    position 1
    association(:survey)
  end
end
