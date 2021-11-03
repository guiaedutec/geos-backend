# frozen_string_literal: true
FactoryGirl.define do
  factory :survey_response do
    in_use false
    vision_level 1
    competence_level 1
    resource_level 1
    infrastructure_level 1
    status 'Complete'
    response_answers []
    association(:school)
    association(:user)
  end
end
