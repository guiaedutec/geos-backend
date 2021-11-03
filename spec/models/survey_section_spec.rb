require 'rails_helper'

RSpec.describe SurveySection, type: :model do
  context 'Fields' do
    it { is_expected.to have_field(:name).of_type(String) }
    it { is_expected.to have_field(:position).of_type(Integer) }
    it { is_expected.to have_field(:description).of_type(String) }

    context 'Relationships' do
      it { is_expected.to belong_to(:survey) }
      it { is_expected.to have_many(:survey_questions) }
    end
  end

  context 'Validations' do
    context 'presence_of' do
      it { is_expected.to validate_presence_of(:name) }
    end
  end

  pending 'add tests to survey_section#add_questions'
  pending 'add tests to survey_section#questions'
  pending 'add tests to survey_section#questions='
end
