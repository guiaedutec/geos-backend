class HomeController < ApplicationController
  def guiaedutec
    base_url = ENV['FRONTEND_URL']
    if user_signed_in?
      redirect_to "#{base_url}/recursos?access_token=#{current_user.authenticity_token}"
    else
      redirect_to base_url
    end
  end
end
