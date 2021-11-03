class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  protect_from_forgery with: :null_session
  respond_to :html, :json
  before_action :authenticate_user_from_token!

private

  def authenticate_user_from_token!
    if access_token = params[:access_token]
      if user = User.find_by(authenticity_token: access_token)
        sign_in user, store: false # store false skips session
      end
    end
  end

  def authenticate_admin!
    redirect_to new_user_session_path, notice: 'Precisa estar logado como admin para acessar este recurso', status: :non_authoritative_information unless current_user && (current_user.admin? || current_user.admin_country?)
  end

  def users_url
    '/users'
  end
end
