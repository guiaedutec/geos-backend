require 'rails_helper'

RSpec.describe Region, type: :model do
  context 'Fields' do
    it { is_expected.to have_field(:name).of_type(String) }

    context 'relations' do
      it { is_expected.to have_many(:states) }
    end
  end

  context 'Validations' do
    context 'presence_of' do
      it { is_expected.to validate_presence_of(:name) }
    end

    context 'uniqueness_of' do
      it { is_expected.to validate_uniqueness_of(:name) }
    end
  end
end
