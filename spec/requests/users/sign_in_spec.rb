require 'rails_helper'

RSpec.describe 'Devise', type: :request do
  describe 'POST /users/sign_in' do
    before(:each) do
      @user = create(
        :user, email: 'autenticacao@devise.com', password: 'autenticacao',
               name: 'Devise', authenticity_token: 'token123')

      post '/users/sign_in.json', params
    end

    describe 'blank parameters' do
      let(:params) { {} }

      it 'has status response 201' do
        expect(response).to have_http_status(201)
      end

      it 'changes sign in count by 0' do
        expect(@user.reload.sign_in_count).to eq(0)
      end

      it 'shows json errors' do
        expect(json_response.keys).to match(['email', 'password'])
      end
    end

    describe 'valid parameters' do
      let(:params) { { access_token: 'token123' } }

      it 'has status response 201' do
        expect(response).to have_http_status(201)
      end

      it 'changes sign in count by 1' do
        expect(@user.reload.sign_in_count).to eq(1)
      end

      it 'has the correct json keys and returns the user' do
        expect(json_response.keys).to match(['_id', '_profile', 'authenticity_token', 'city_id', 'created_at', 'email', 'institution', 'name', 'regional', 'response', 'role', 'school_id', 'state_id', 'updated_at', 'has_answered_survey', 'inep_code'])
      end
    end
  end
end
