require 'rails_helper'

RSpec.describe CitiesController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/cidades').to route_to('cities#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/cidades/new').to route_to('cities#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/cidades/1').to route_to('cities#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/cidades/1/edit').to route_to('cities#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/cidades').to route_to('cities#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/cidades/1').to route_to('cities#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/cidades/1').to route_to('cities#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/cidades/1').to route_to('cities#destroy', id: '1')
    end
  end
end
