require 'rails_helper'

RSpec.describe Manager, type: :model do
  context 'Fields' do
    it { is_expected.to have_field(:name).of_type(String) }
    it { is_expected.to have_field(:email).of_type(String) }
    it { is_expected.to have_field(:phone).of_type(String) }

    context 'Relationships' do
      it { is_expected.to have_many(:schools) }
    end
  end

  context 'Validations' do
    context 'uniqueness_of' do
      it { is_expected.to validate_uniqueness_of(:email) }
    end
  end
end
