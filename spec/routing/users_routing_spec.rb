require 'rails_helper'

RSpec.describe UsersController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/usuarios').to route_to('users#index')
    end

    it 'routes to #new' do
      expect(get: '/admin/usuarios/new').to route_to('users#new')
    end

    it 'routes to #show' do
      expect(get: '/admin/usuarios/1').to route_to('users#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/admin/usuarios/1/edit').to route_to('users#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/admin/usuarios').to route_to('users#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/admin/usuarios/1').to route_to('users#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/admin/usuarios/1').to route_to('users#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/admin/usuarios/1').to route_to('users#destroy', id: '1')
    end
  end
end
