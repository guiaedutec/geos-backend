require 'rails_helper'

RSpec.describe TranslationController, type: :controller do

  describe "GET #get_translantion_by_lang" do
    it "returns http success" do
      get :get_translantion_by_lang
      expect(response).to have_http_status(:success)
    end
  end

end
