# frozen_string_literal: true
require 'rails_helper'

describe SchoolAnswerSearch, type: :model do
  let(:query) { nil }
  let(:sort_field) { nil }
  let(:sort_direction) { nil }
  let(:state) { nil }
  let(:filters) { {} }
  let(:page) { nil }
  let(:search_params) do
    {
      query: query,
      sort_field: sort_field,
      sort_direction: sort_direction,
      state: state,
      filters: filters,
      page: page
    }
  end

  subject(:school_answer_search) do
    described_class.new(search_params)
  end

  describe '#answers' do
    context 'without filters or sorting' do
      let!(:school_with_answer) { create :school }
      let!(:school_no_answer)   { create :school }
      let(:user) { create :user, school: school_with_answer }
      let!(:survey_response) { create :survey_response, school: school_with_answer, user: user }

      its('answers.count') { is_expected.to eq 2 }

      it 'by default orders by those who have answered' do
        [school_with_answer, school_no_answer].each do |school|
          expect(school_answer_search.answers.to_a.map).to be_include school
        end
      end
    end

    context 'with state filters' do
      let(:state) { create :state }
      let(:city)  { create :city, state: state }
      let!(:school_a) { create :school, city: city }
      let!(:school_b) { create :school }

      its('answers.to_a') { is_expected.to eq [school_a] }
    end

    context 'with regional filter' do
      let(:regional) { 'região 1' }
      let!(:school_a) { create :school, regional: regional }
      let!(:school_b) { create :school }

      subject(:school_answer_search) do
        described_class.new(search_params.merge(regional: regional))
      end

      its('answers.to_a') { is_expected.to eq [school_a] }
    end

    context 'with query' do
      let!(:school_a) { create :school, name: 'EMEF Atibaia', inep_code: '111111' }
      let!(:school_b) { create :school, name: 'EMEF Jacareí', inep_code: '222222' }
      let(:sort_field) { 'name' }

      context 'query=Jacareí' do
        let(:query) { 'Jacareí' }
        its('answers.to_a') { is_expected.to eq [school_b] }
      end

      context 'query=emef' do
        let(:query) { 'emef' }
        its('answers.to_a') { is_expected.to eq [school_a, school_b] }
      end

      context 'query=111111' do
        let(:query) { '111111' }
        its('answers.to_a') { is_expected.to eq [school_a] }
      end

      context 'query=kkkkkk' do
        let(:query) { 'kkkkkk' }
        its('answers.to_a') { is_expected.to eq [] }
      end
    end

    context 'with filters' do
      let!(:school_a) { create(:school, name: 'a', sample: true) }
      let!(:school_b) { create :school, name: 'b', sample: false }
      let!(:school_c) { create :school, name: 'c', sample: false }
      let(:user_a) { create :user, school: school_a }
      let(:user_b) { create :user, school: school_b }
      let!(:response_a) do
        create :survey_response, vision_level: 2, competence_level: 2, resource_level: 2, infrastructure_level: 2, school: school_a, user: user_a
      end

      let!(:response_b) do
        create :survey_response, vision_level: 4, competence_level: 4, resource_level: 4, infrastructure_level: 4, school: school_b, user: user_b
      end

      let(:sort_field) { 'school_name' }

      context 'sample' do
        let(:filters) { { sample: ['true'] } }
        its('answers.to_a') do
          is_expected.to eq [school_a]
        end
      end

      context 'sample' do
        let(:filters) { { sample: ['false'] } }
        its('answers.to_a') { is_expected.to eq [school_b, school_c] }
      end

      context 'sample' do
        let(:filters) { { sample: ['true', 'false'] } }
        its('answers.to_a') { is_expected.to eq [school_a, school_b, school_c] }
      end

      context 'answered' do
        let(:filters) { { answered: ['true'] } }
        its('answers.to_a') do
          [school_a, school_b].each { |school| is_expected.to be_include school }
        end
      end

      context 'answered' do
        let(:filters) { { answered: ['false'] } }
        its('answers.to_a') { is_expected.to eq [school_c] }
      end

      context 'answered' do
        let(:filters) { { answered: ['true', 'false'] } }
        its('answers.to_a') { is_expected.to eq [school_a, school_b, school_c] }
      end

      context 'vision_level' do
        let(:filters) { { vision_level: [2, 3] } }
        its('answers.to_a') { is_expected.to eq [school_a] }
      end

      context 'competence_level' do
        let(:filters) { { competence_level: [2, 3] } }
        its('answers.to_a') { is_expected.to eq [school_a] }
      end

      context 'resource_level' do
        let(:filters) { { resource_level: [2, 3] } }
        its('answers.to_a') { is_expected.to eq [school_a] }
      end

      context 'infrastructure_level' do
        let(:filters) { { infrastructure_level: [2, 3] } }
        its('answers.to_a') { is_expected.to eq [school_a] }
      end

      context 'vision_level and competence_level' do
        let(:filters) { { vision_level: [2], competence_level: [4] } }
        its('answers.to_a') { is_expected.to eq [] }
      end

      context 'vision_level and competence_level' do
        let(:filters) { { vision_level: [2], competence_level: [2] } }
        its('answers.to_a') { is_expected.to eq [school_a] }
      end
    end

    context 'with sorting' do
      context 'sample' do
        let(:sort_field) { 'sample' }
        let!(:school_a) { create :school, sample: true }
        let!(:school_b) { create :school, sample: false }

        context 'asc' do
          let(:sort_direction) { 'asc' }
          its('answers.to_a') { is_expected.to eq [school_b, school_a] }
        end

        context 'desc' do
          let(:sort_direction) { 'desc' }
          its('answers.to_a') { is_expected.to eq [school_a, school_b] }
        end
      end

      context 'vision_level' do
        let(:sort_field) { 'vision_level' }
        let!(:school_a) { create :school, vision_level: 1 }
        let!(:school_b) { create :school, vision_level: 2 }

        context 'asc' do
          let(:sort_direction) { 'asc' }
          its('answers.to_a') { is_expected.to eq [school_a, school_b] }
        end

        context 'desc' do
          let(:sort_direction) { 'desc' }
          its('answers.to_a') { is_expected.to eq [school_b, school_a] }
        end
      end

      context 'competence_level' do
        let(:sort_field) { 'competence_level' }
        let!(:school_a) { create :school, competence_level: 1 }
        let!(:school_b) { create :school, competence_level: 2 }

        context 'asc' do
          let(:sort_direction) { 'asc' }
          its('answers.to_a') { is_expected.to eq [school_a, school_b] }
        end

        context 'desc' do
          let(:sort_direction) { 'desc' }
          its('answers.to_a') { is_expected.to eq [school_b, school_a] }
        end
      end

      context 'resource_level' do
        let(:sort_field) { 'resource_level' }
        let!(:school_a) { create :school, resource_level: 1 }
        let!(:school_b) { create :school, resource_level: 2 }

        context 'asc' do
          let(:sort_direction) { 'asc' }
          its('answers.to_a') { is_expected.to eq [school_a, school_b] }
        end

        context 'desc' do
          let(:sort_direction) { 'desc' }
          its('answers.to_a') { is_expected.to eq [school_b, school_a] }
        end
      end

      context 'infrastructure_level' do
        let(:sort_field) { 'infrastructure_level' }
        let!(:school_a) { create :school, infrastructure_level: 1 }
        let!(:school_b) { create :school, infrastructure_level: 2 }

        context 'asc' do
          let(:sort_direction) { 'asc' }
          its('answers.to_a') { is_expected.to eq [school_a, school_b] }
        end

        context 'desc' do
          let(:sort_direction) { 'desc' }
          its('answers.to_a') { is_expected.to eq [school_b, school_a] }
        end
      end

      context 'answered' do
        let(:sort_field) { 'answered' }
        let!(:school_with_answer) { create :school }
        let!(:school_no_answer) { create :school }
        let(:user) { create :user, school: school_with_answer }
        let!(:survey_response) { create :survey_response, school: school_with_answer, user: user }

        context 'asc' do
          let(:sort_direction) { 'asc' }
          its('answers.to_a') { is_expected.to eq [school_no_answer, school_with_answer] }
        end

        context 'desc' do
          let(:sort_direction) { 'desc' }
          its('answers.to_a') { is_expected.to eq [school_with_answer, school_no_answer] }
        end
      end

      context 'inep' do
        let(:sort_field) { 'inep' }
        let!(:school_a) { create :school, inep_code: 'a' }
        let!(:school_b) { create :school, inep_code: 'b' }

        context 'asc' do
          let(:sort_direction) { 'asc' }
          its('answers.to_a') { is_expected.to eq [school_a, school_b] }
        end

        context 'desc' do
          let(:sort_direction) { 'desc' }
          its('answers.to_a') { is_expected.to eq [school_b, school_a] }
        end
      end

      context 'school_name' do
        let(:sort_field) { 'school_name' }
        let!(:school_a) { create :school, name: 'a' }
        let!(:school_b) { create :school, name: 'b' }

        its('answers.to_a') { is_expected.to eq [school_a, school_b] }

        context 'asc' do
          let(:sort_direction) { 'asc' }
          its('answers.to_a') { is_expected.to eq [school_a, school_b] }
        end

        context 'desc' do
          let(:sort_direction) { 'desc' }
          its('answers.to_a') { is_expected.to eq [school_b, school_a] }
        end
      end
    end
  end

  describe 'counts' do
    before do
      4.times { create :school, sample: true }
      6.times { create :school, sample: false }
      s = create(:school, sample: true)
      u = create(:user, school: s)
      create(:survey_response, school: s, user: u)
      s = create(:school, sample: false)
      u = create(:user, school: s)
      create(:survey_response, school: s, user: u)
    end

    describe '#total_count' do
      its('total_count') { is_expected.to eq 12 }
    end

    describe '#answered_count' do
      its('answered_count') { is_expected.to eq 2 }
    end

    describe '#total_sample_count' do
      its('total_sample_count') { is_expected.to eq 5 }
    end

    describe '#answered_sample_count' do
      its('answered_sample_count') { is_expected.to eq 1 }
    end

    describe '#pages_count' do
      its('pages_count') { is_expected.to eq 1 }
    end

    describe '#answers.count' do
      its('answers.count') { is_expected.to eq 12 }
    end
  end
end
