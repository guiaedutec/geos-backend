require 'rails_helper'

describe Survey, type: :model do
  context 'class relationships' do
    it 'Survey has_many SurveyResponse' do
      is_expected.to have_many(:survey_responses)
    end

    it 'Survey has_many SurveySection' do
      is_expected.to have_many(:survey_sections)
      is_expected.to have_many(:survey_questions)
    end
  end


  context 'Validations' do
    context 'presence_of' do
      # it { is_expected.to validate_presence_of(:surveygizmo_id) }
      # it { is_expected.to validate_presence_of(:students_per_computer_id) }
    end
  end
end
