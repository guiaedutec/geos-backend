require 'rails_helper'

RSpec.describe SurveyAnswer, type: :model do
  context 'Fields' do
    it { is_expected.to have_field(:value).of_type(String) }
    it { is_expected.to have_field(:position).of_type(Integer) }
    it { is_expected.to have_field(:survey_answer_id).of_type(Integer) }

    context 'Relationships' do
      it { is_expected.to belong_to(:survey_question) }
    end
  end

  context 'Validations' do
    context 'presence_of' do
      it { is_expected.to validate_presence_of(:value) }
    end
  end
end
