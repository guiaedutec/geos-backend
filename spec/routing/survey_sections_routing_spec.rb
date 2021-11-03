require 'rails_helper'

RSpec.describe SurveySectionsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/secoes').to route_to('survey_sections#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/secoes/new').to route_to('survey_sections#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/secoes/1').to route_to('survey_sections#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/secoes/1/edit').to route_to('survey_sections#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/secoes').to route_to('survey_sections#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/secoes/1').to route_to('survey_sections#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/secoes/1').to route_to('survey_sections#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/secoes/1').to route_to('survey_sections#destroy', id: '1')
    end
  end
end
