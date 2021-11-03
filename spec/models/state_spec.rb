require 'rails_helper'

RSpec.describe State, type: :model do
  context 'Fields' do
    it { is_expected.to have_field(:name).of_type(String) }
    it { is_expected.to have_field(:acronym).of_type(String) }

    context 'relations' do
      it { is_expected.to have_many(:cities) }
      it { is_expected.to belong_to(:region) }
    end
  end

  context 'Validations' do
    context 'presence_of' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:acronym) }
    end

    context 'uniqueness_of' do
      it { is_expected.to validate_uniqueness_of(:name) }
      it { is_expected.to validate_presence_of(:acronym) }
    end
  end

  describe '::find_by_acronym' do
    let!(:state) { create :state, acronym: 'SP' }
    it 'finds by acronym if it exists' do
      expect(described_class.find_by_acronym('SP')).to eq state
    end

    it 'returns nil if it doesnt exists' do
      expect(described_class.find_by_acronym('MJ')).to be_nil
    end
  end
end
