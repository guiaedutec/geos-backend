# frozen_string_literal: true
require 'rails_helper'

describe ApplicationHelper, type: :helper do
  describe '#score_name' do
    subject { helper.score_level_and_name(level) }

    context 'when level is 1' do
      let(:level) { 1 }
      it { is_expected.to eq 'Nível 1 (Emergente)' }
    end

    context 'when level is 2' do
      let(:level) { 2 }
      it { is_expected.to eq 'Nível 2 (Básico)' }
    end

    context 'when level is 3' do
      let(:level) { 3 }
      it { is_expected.to eq 'Nível 3 (Intermediário)' }
    end

    context 'when level is 4' do
      let(:level) { 4 }
      it { is_expected.to eq 'Nível 4 (Avançado)' }
    end

    context 'when level is anything else' do
      let(:level) { nil }
      it { is_expected.to eq '' }
    end
  end

  describe '#profile_options' do
    subject { helper.profile_options }
    let(:profile_options) do
      [
        ['Diretor', :principal],
        ['Outros', :other],
        ['Professor', :teacher],
        ['Admin', :admin],
        ['Admin Regional', :local_admin],
        ['Gestor Estado', :admin_state],
        ['Gestor Cidade', :admin_city]
      ]
    end
    it { is_expected.to eq profile_options }
  end

  describe '#activity_options' do
    subject { helper.activity_options }
    let(:activity_options) do
      [
          ['Escola', :school],
          ['Professor', :teacher]
      ]
    end
    it { is_expected.to eq activity_options }
  end
end
