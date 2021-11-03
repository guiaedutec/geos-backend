FactoryGirl.define do
  factory :survey_question do
    name "MyString"
    position 1
    association(:survey_section)
  end
end
