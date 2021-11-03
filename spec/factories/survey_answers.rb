FactoryGirl.define do
  factory :survey_answer do
    value "MyString"
    position 1
    survey_answer_id 1
    association(:survey_question)
  end
end
