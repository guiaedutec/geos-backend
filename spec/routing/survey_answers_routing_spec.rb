require 'rails_helper'

RSpec.describe SurveyAnswersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/respostas').to route_to('survey_answers#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/respostas/new').to route_to('survey_answers#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/respostas/1').to route_to('survey_answers#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/respostas/1/edit').to route_to('survey_answers#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/respostas').to route_to('survey_answers#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/respostas/1').to route_to('survey_answers#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/respostas/1').to route_to('survey_answers#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/respostas/1').to route_to('survey_answers#destroy', id: '1')
    end
  end
end
