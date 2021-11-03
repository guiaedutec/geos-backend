require 'rails_helper'

RSpec.describe SurveyQuestion, type: :model do
  context 'Fields' do
    it { is_expected.to have_field(:name).of_type(String) }
    it { is_expected.to have_field(:position).of_type(Integer) }
    it { is_expected.to have_field(:type).of_type(String) }

    context 'Relationships' do
      it { is_expected.to have_many(:survey_answers) }
      it { is_expected.to have_many(:response_answers) }
      it { is_expected.to have_many(:sub_questions) }
      it { is_expected.to belong_to(:main_question) }
      it { is_expected.to belong_to(:survey) }
      it { is_expected.to belong_to(:survey_section) }
    end
  end

  context 'Validations' do
    context 'presence_of' do

    end
  end

  pending 'add tests to survey_question#add_question'

  context '#open_answer?' do
    it 'is false for checkbox' do
      expect(build(:survey_question, type: 'checkbox')).not_to be_open_answer
    end

    it 'is false for radio' do
      expect(build(:survey_question, type: 'radio')).not_to be_open_answer
    end

    it 'is true for other' do
      expect(build(:survey_question, type: 'other')).to be_open_answer
    end
  end

  describe '#computer_count_question?' do
    let(:survey) { create :survey }
    let(:survey_section) { create :survey_section, survey: survey }
    let(:matching_question) { build :survey_question, survey_section: survey_section }
    let(:non_matching_question) { build :survey_question, survey_section: survey_section }

    it 'is true if its id matches survey#students_per_computer_id' do
      expect(matching_question).to be_computer_count_question
    end

    it 'is false if its id does not matches survey#students_per_computer_id' do
      expect(non_matching_question).not_to be_computer_count_question
    end
  end
end
