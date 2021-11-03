# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'Devise', type: :request do
  describe 'POST /users' do
    before(:each) do
      post '/users.json', params
    end

    describe 'blank parameters' do
      let(:params) { {} }

      it 'has status response 422' do
        expect(response).to have_http_status(422)
      end

      it 'shows json errors' do
        expect(json_response).to eq(
          'errors' => {
            'email' => ['não pode ficar em branco'],
            'password' => ['não pode ficar em branco'],
            'name' => ['não pode ficar em branco'],
            'state_id' => ['não pode ficar em branco'],
            'school_id' => ['não pode ficar em branco']
          }
        )
      end
    end

    describe 'valid parameters' do
      let(:state) { create(:state, name: 'São Paulo', acronym: 'SP') }
      let(:city) { create(:city, state: state, name: 'São Paulo', capital: true) }
      let(:school) { create(:school, city: city) }
      let(:params) do
        { user: { email: 'foo@bar.com', password: 'foobar', name: 'Foo', city_id: city.to_param, state_id: state.to_param, school_id: school.to_param } }
      end

      it 'has status response 201' do
        expect(response).to have_http_status(201)
      end

      it 'has the correct json keys and returns the user' do
        expect(json_response.keys).to match(['_id', '_profile', 'authenticity_token', 'city_id', 'created_at', 'email', 'institution', 'name', 'regional', 'response', 'role', 'school_id', 'state_id', 'updated_at', 'has_answered_survey', 'inep_code'])
      end
    end
  end
end
