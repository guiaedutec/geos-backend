require 'rails_helper'

RSpec.describe RegionsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/regioes').to route_to('regions#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/regioes/new').to route_to('regions#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/regioes/1').to route_to('regions#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/regioes/1/edit').to route_to('regions#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/regioes').to route_to('regions#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/regioes/1').to route_to('regions#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/regioes/1').to route_to('regions#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/regioes/1').to route_to('regions#destroy', id: '1')
    end
  end
end
