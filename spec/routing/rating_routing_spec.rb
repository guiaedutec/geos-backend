require 'rails_helper'

RSpec.describe RatingController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/admin/rating').to route_to('rating#index')
    end
  end
end
