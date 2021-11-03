require 'rails_helper'

RSpec.describe City, type: :model do
  context 'Fields' do
    it { is_expected.to have_field(:name).of_type(String) }
    it { is_expected.to have_field(:capital).of_type(Mongoid::Boolean) }

    context 'Relationships' do
      it { is_expected.to have_many(:users) }
      it { is_expected.to have_many(:schools) }
    end
  end

  context 'Validations' do
    context 'presence_of' do
      it { is_expected.to validate_presence_of(:name) }
    end
  end

  describe '#uf_ibge_code' do
    context 'with an ibge' do
      subject { build :city, ibge_code: '112233' }

      its(:uf_ibge_code){ is_expected.to eq '11' }
    end

    context 'without an ibge' do
      subject { build :city, ibge_code: nil }

      its(:uf_ibge_code){ is_expected.to be nil }
    end

  end
end
