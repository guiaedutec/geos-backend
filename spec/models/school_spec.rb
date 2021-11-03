# frozen_string_literal: true
require 'rails_helper'

RSpec.describe School, type: :model do
  describe 'Fields' do
    it { is_expected.to have_field(:name) }
    it { is_expected.to have_field(:inep_code) }
    it { is_expected.to have_field(:staff_count) }
    it { is_expected.to have_field(:private) }
    it { is_expected.to have_field(:type) }
    it { is_expected.to have_field(:location_type) }
    it { is_expected.to have_field(:sample) }
    it { is_expected.to have_field(:observations) }
    it { is_expected.to belong_to(:city) }
    it { is_expected.to belong_to(:manager) }
    it { is_expected.to have_many(:survey_responses) }
    it { is_expected.to have_many(:users) }

    describe 'student count fields' do
      it { is_expected.to have_field(:student_diurnal_count) }
      it { is_expected.to have_field(:student_vespertine_count) }
      it { is_expected.to have_field(:student_nocturnal_count) }
      it { is_expected.to have_field(:student_full_count) }
    end

    context 'Validations' do
      context 'presence_of' do
        it { is_expected.to validate_presence_of(:name) }
      end

      context 'uniqueness_of' do
        it { is_expected.to validate_uniqueness_of(:name).scoped_to(:city) }
      end
    end
  end

  context 'Relationships' do
    it { is_expected.to belong_to(:city) }
    it { is_expected.to have_many(:users) }
  end

  describe '#oldest_survey_response' do
    let!(:school) { create :school }
    let!(:older) { create :survey_response, vision_level: 1, submitted_at: 1.hour.ago, status: 'Complete', school: school }
    let!(:incomplete_older) { create :survey_response, vision_level: 2, submitted_at: 2.hours.ago, status: 'Partial', school: school }
    let!(:newer) { create :survey_response, vision_level: 4, submitted_at: 5.minutes.ago, status: 'Complete', school: school }

    it 'returns the oldest complete survey' do
      expect(school.oldest_survey_response).to eq older
      expect(school.vision_level).to eq 1
    end

    it 'returns nil if theres no complete survey' do
      school = create :school
      create :survey_response, vision_level: 2, submitted_at: 2.hours.ago, status: 'Partial', school: school
      expect(school.oldest_survey_response).to be_nil
    end

    describe 'update_levels' do
      it 'changes the school levels according to oldest survey response' do
        expect { older.update(vision_level: 3) }.to change { school.reload.vision_level }.from(1).to(3)
      end

      it 'doenst changes the school levels if it isnt the oldest survey response' do
        expect { newer.update(vision_level: 3) }.not_to change { school.vision_level }
      end
    end
  end

  describe '#max_shift_students' do
    let(:school_with_no_students) { build :school, student_diurnal_count: nil, student_vespertine_count: nil, student_nocturnal_count: nil, student_full_count: nil }
    let(:school_10_students) { build :school, student_diurnal_count: 1, student_vespertine_count: 2, student_nocturnal_count: 3, student_full_count: 4 }

    it 'calculates the max shift value' do
      expect(school_10_students.max_shift_students).to eq 4
    end

    it 'is zero if no value is given' do
      expect(school_with_no_students.max_shift_students).to be_zero
    end
  end

  describe '#student_count' do
    let(:school_with_no_students) { build :school, student_diurnal_count: nil, student_vespertine_count: nil, student_nocturnal_count: nil, student_full_count: nil }
    let(:school_10_students) { build :school, student_diurnal_count: 1, student_vespertine_count: 2, student_nocturnal_count: 3, student_full_count: 4 }

    it 'sums student count fields' do
      expect(school_10_students.student_count).to eq 10
    end

    it 'defaults to 0' do
      expect(school_with_no_students.student_count).to be_zero
    end
  end

  context 'Factory' do
    let(:school) { build :school }

    it 'expects to have a valid factory' do
      expect(school).to be_valid
    end

    it 'expects the factory to be persisted' do
      school.save
      expect(school).to be_persisted
    end
  end

  describe '#city_name' do
    let(:city) { create :city, name: 'Atibaia' }
    it 'is equal to city.name' do
      expect(create(:school, city: city).city_name).to eq 'Atibaia'
    end
  end

  describe '#ordered scope' do
    let!(:school_b) { create :school, name: 'b' }
    let!(:school_a) { create :school, name: 'a' }
    let!(:school_c) { create :school, name: 'c' }

    it 'orders schools by name' do
      expect(described_class.ordered.map(&:name)).to eq %w(a b c)
    end
  end
end
