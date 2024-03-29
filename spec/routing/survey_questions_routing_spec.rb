require 'rails_helper'

RSpec.describe SurveyQuestionsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/questoes').to route_to('survey_questions#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/questoes/new').to route_to('survey_questions#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/questoes/1').to route_to('survey_questions#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/questoes/1/edit').to route_to('survey_questions#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/questoes').to route_to('survey_questions#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/questoes/1').to route_to('survey_questions#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/questoes/1').to route_to('survey_questions#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/questoes/1').to route_to('survey_questions#destroy', id: '1')
    end
  end
end
