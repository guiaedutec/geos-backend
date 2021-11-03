require 'rails_helper'

RSpec.describe 'SchoolSpec via API', type: :request do
  describe 'PUT update on api/v1/schools/school_id' do
    it 'changes the school observation' do
      user = create(:user, email: 'user@test.com')
      school = create(:school, observations: '')
      params = { access_token: user.authenticity_token, school: { observations: 'Observation' } }

      put api_v1_school_path(school.id), params

      expect(school.reload.observations).to eq('Observation')
    end
  end
end
