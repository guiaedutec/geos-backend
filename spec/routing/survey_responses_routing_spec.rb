require 'rails_helper'

RSpec.describe SurveyResponsesController, type: :routing do
  describe 'routing' do
    it 'routes to #issues' do
      expect(get: '/admin/devolutivas/problematicas').to route_to('survey_responses#issues')
    end

    it 'routes to #index' do
      expect(get: '/admin/devolutivas').to route_to('survey_responses#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/devolutivas/new').to route_to('survey_responses#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/devolutivas/1').to route_to('survey_responses#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/devolutivas/1/edit').to route_to('survey_responses#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/devolutivas').to route_to('survey_responses#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/devolutivas/1').to route_to('survey_responses#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/devolutivas/1').to route_to('survey_responses#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/devolutivas/1').to route_to('survey_responses#destroy', id: '1')
    end
  end
end
