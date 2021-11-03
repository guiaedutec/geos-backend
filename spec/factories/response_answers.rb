FactoryGirl.define do
  factory :response_answer do
    answer 1
    association :survey_question
    association :survey_response
  end
end
