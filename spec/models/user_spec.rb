# frozen_string_literal: true
require 'rails_helper'

RSpec.describe User, type: :model do
  context 'Validations' do
    context 'presence_of' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:email) }
      it { is_expected.to validate_presence_of(:password) }
      it { is_expected.to validate_presence_of(:state_id) }
      it { is_expected.to validate_presence_of(:school_id) }
    end

    context 'uniqueness_of' do
      it { is_expected.to validate_uniqueness_of(:email) }
      it { is_expected.to validate_uniqueness_of(:authenticity_token) }
    end

    it 'has a valid factory' do
      expect(build(:user)).to be_valid
      expect(create(:user)).to be_persisted
    end
  end

  context 'Fields' do
    it { is_expected.to have_field(:role).of_type(String) }
    it { is_expected.to have_field(:institution).of_type(String) }
    it { is_expected.to have_field(:regional).of_type(String) }
  end

  context 'Relationships' do
    it { is_expected.to belong_to(:city) }
    it { is_expected.to belong_to(:state) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:institution) }
    it { is_expected.to have_one(:survey_response) }
  end

  describe '#generate_authentication_token!' do
    it 'generates an unique token' do
      allow(Devise).to receive(:friendly_token).and_return('token123')
      user = create(:user)

      expect(user.authenticity_token).to eq('token123')
    end
  end

  describe 'scopes' do
    describe 'principal_or_teacher' do
      let!(:teacher) { create :user, profile: 'teacher' }
      let!(:principal) { create :user, profile: 'principal' }
      let!(:other) { create :user, profile: 'other' }

      it 'returns users with profile teacher' do
        expect(described_class.principal_or_teacher).to include(teacher)
      end

      it 'returns users with profile principal' do
        expect(described_class.principal_or_teacher).to include(principal)
      end

      it 'doesnt return users with other profiles' do
        expect(described_class.principal_or_teacher).not_to include(other)
      end
    end
  end

  describe '#inep_code' do
    let!(:school) { create :school, inep_code: '111111' }
    let(:profile) { 'principal' }
    let(:inep_code) { '111111' }
    let(:user) { build :user, school_id: nil, inep_code: inep_code, profile: profile }
    before { user.save }

    it 'associates user to a school with the same inep' do
      expect(user).to be_valid
      expect(user.school).to eq school
    end

    context 'principal' do
      let(:inep_code) { '111112' }

      it 'raises error if no school or inep is found' do
        expect(user).not_to be_valid
      end
    end

    context 'teacher' do
      let(:profile) { 'teacher' }
      let(:inep_code) { '111112' }

      it 'raises error if no school or inep is found' do
        expect(user).not_to be_valid
      end
    end

    context 'other' do
      let(:profile) { 'other' }
      let(:inep_code) { '111112' }

      it 'raises no error if no school or inep is found' do
        expect(user).to be_valid
        expect(user.school).to be_blank
      end
    end

    describe '#admin?' do
      let(:user) { build :user }
      let(:admin) { build :admin }
      let(:local_admin) { build :local_admin }

      it 'is an admin if its profile is admin or local_admin' do
        expect(user).not_to be_an_admin
        expect(admin).to be_admin
        expect(local_admin).to be_admin
      end
    end

    describe '#local_admin?' do
      let(:user) { build :user }
      let(:admin) { build :admin }
      let(:local_admin) { build :local_admin }

      it 'is an admin if its profile is local_admin' do
        expect(user).not_to be_a_local_admin
        expect(admin).not_to be_a_local_admin
        expect(local_admin).to be_a_local_admin
      end
    end
  end

  describe 'incomplete response' do
    let!(:user_without_response) { create :user }
    let!(:user_with_complete_response) { create :user }
    let!(:user_with_incomplete_response) { create :user }
    let!(:user_with_deleted_response) { create :user }
    let!(:complete_survey_response) { create :survey_response, user: user_with_complete_response, status: 'Complete' }
    let!(:incomplete_survey_response) { create :survey_response, user: user_with_incomplete_response, status: 'Partial' }
    let!(:deleted_survey_response) { create :survey_response, user: user_with_deleted_response, status: 'Deleted' }

    it 'finds users with no survey response' do
      expect(described_class.without_response).to include(user_without_response)
    end

    it 'finds users with incomplete survey response' do
      expect(described_class.without_response).to include(user_without_response)
    end

    it 'doesnt find users with complete survey response' do
      expect(described_class.without_response).not_to include(user_with_complete_response)
    end

    it 'doesnt find users with deleted survey response' do
      expect(described_class.without_response).not_to include(user_with_deleted_response)
    end
  end
end
