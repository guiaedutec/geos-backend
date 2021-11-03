# frozen_string_literal: true
require 'rails_helper'

describe SurveyResponse do
  let(:survey_response) { build :survey_response }

  context 'Fields' do
    it { is_expected.to have_field(:status).of_type(String) }
    it { is_expected.to have_field(:submitted_at).of_type(DateTime) }
    it { is_expected.to have_field(:number_of_tries_left).of_type(Integer) }
    it { is_expected.to have_field(:in_use).of_type(Mongoid::Boolean) }
  end

  context 'Relations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:school) }
  end

  it 'expects to have a valid factory' do
    expect(survey_response).to be_valid
  end

  it 'expects the factory to be persisted' do
    survey_response.save
    expect(survey_response).to be_persisted
  end

  context 'Validations' do
    context 'presence_of' do
      it { is_expected.to validate_presence_of(:school_id) }
    end
  end

  context 'Scopes' do
    describe 'default scope' do
      let!(:newer) { create :survey_response, submitted_at: 5.minutes.ago }
      let!(:older) { create :survey_response, submitted_at: 1.hour.ago }

      it 'orders by submitted_at oldest first' do
        expect(described_class.all.to_a).to eq [older, newer]
      end
    end

    describe 'issues' do
      let!(:complete_survey_without_issue) { create :survey_response, infrastructure_level: 1, vision_level: 2, competence_level: 3, resource_level: 4, status: 'Complete' }
      let!(:complete_survey_with_issue) { create :survey_response, infrastructure_level: 0, status: 'Complete' }
      let!(:partial_survey_without_issue) { create :survey_response, infrastructure_level: 0, vision_level: 0, competence_level: 0, resource_level: 0, status: 'Partial' }

      it 'finds surveys with issues' do
        expect(described_class.issue).to include(complete_survey_with_issue)
        expect(complete_survey_with_issue).not_to be_complete

        expect(described_class.issue).not_to include(partial_survey_without_issue)
        expect(partial_survey_without_issue).not_to be_complete

        expect(described_class.issue).not_to include(complete_survey_without_issue)
        expect(complete_survey_without_issue).to be_complete
      end
    end
  end

  describe '#decrease_number_of_tries_left' do
    subject(:response) { create :survey_response, number_of_tries_left: 3 }

    it 'decreases the number_of_tries by 1' do
      expect { response.decrease_number_of_tries_left }.to change { response.number_of_tries_left }.from(3).to(2)
      expect { response.decrease_number_of_tries_left }.to change { response.number_of_tries_left }.from(2).to(1)
    end
  end

  describe '#reset_number_of_tries' do
    subject(:response) { create :survey_response, number_of_tries_left: 4 }

    it 'changes the number_of_tries to 1' do
      expect { response.reset_number_of_tries }.to change { response.number_of_tries_left }.from(4).to(1)
    end
  end

  describe 'complete' do
    let!(:complete_response) { create :survey_response, status: 'Complete' }
    let!(:incomplete_response) { create :survey_response, status: 'Partial' }
    let!(:deleted_response) { create :survey_response, status: 'Deleted' }

    it 'finds complete survey responses' do
      expect(described_class.complete).to include(complete_response)
      expect(described_class.complete).not_to include(incomplete_response)
      expect(described_class.complete).not_to include(deleted_response)
    end
  end

  describe 'incomplete' do
    let!(:complete_response) { create :survey_response, status: 'Complete' }
    let!(:incomplete_response) { create :survey_response, status: 'Partial' }
    let!(:deleted_response) { create :survey_response, status: 'Deleted' }

    it 'finds incomplete survey responses' do
      expect(described_class.incomplete).to include(incomplete_response)
      expect(described_class.incomplete).not_to include(complete_response)
      expect(described_class.incomplete).not_to include(deleted_response)
    end
  end

  describe 'deleted' do
    let!(:complete_response) { create :survey_response, status: 'Complete' }
    let!(:incomplete_response) { create :survey_response, status: 'Partial' }
    let!(:deleted_response) { create :survey_response, status: 'Deleted' }

    it 'finds complete survey responses' do
      expect(described_class.deleted).to include(deleted_response)
      expect(described_class.deleted).not_to include(complete_response)
      expect(described_class.deleted).not_to include(incomplete_response)
    end
  end

  describe 'in_use' do
    let!(:school) { create :school }
    let!(:user) { create :user, school: school }
    before { school.update vision_level: 1 }

    describe 'set_in_use' do
      let!(:response) { create :survey_response, vision_level: 2, school: school, user: user, status: 'Partial' }

      it 'changes in_use to true' do
        expect { response.set_in_use }.to change { response.in_use }.from(false).to(true)
      end

      it 'doesnt change school data' do
        expect { response.set_in_use }.not_to change { school.vision_level }
      end
    end

    describe 'set_not_in_use' do
      let!(:response) { create :survey_response, vision_level: 2, school: school, user: user, status: 'Complete' }

      it 'changes in_use to false' do
        expect { response.set_not_in_use }.to change { response.reload.in_use }.from(true).to(false)
      end

      it 'doesnt change school data' do
        expect { response.set_not_in_use }.not_to change { school.vision_level }
      end
    end
  end
end
