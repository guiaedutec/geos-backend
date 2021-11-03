require 'rails_helper'

RSpec.describe SpreadSheetsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(post: '/admin/inspirese').to route_to('spread_sheets#index')
    end
  end
end
