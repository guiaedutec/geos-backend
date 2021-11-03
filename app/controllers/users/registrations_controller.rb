module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [:create]
    layout 'admin'

  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  def sign_up_params
    sanitized_params = devise_parameter_sanitizer.sanitize(:sign_up)
    if sanitized_params[:state_id] && sanitized_params[:state_id].size == 2
      sanitized_params[:state_id] = State.find_by(acronym: sanitized_params[:state_id]).to_param
    end
    sanitized_params
  end

  # {"user":{"name":"Novo Mais","email":"mail@mail.com","password":"123456","state_id":"AL","profile":"principal","city_id":"57db420357f3170003d9fd91","inep_code":"434343","school_id":"580e31d59f7b400003ff69b1"}}

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

    # If you have extra params to permit, append them to the sanitizer.
    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up,
        keys: [:name, :state_id, :city_id, :role, :profile, :institution, :school_id])
    end

    # The path used after sign up.
    # def after_sign_up_path_for(resource)
    #   super(resource)
    # end

    # The path used after sign up for inactive accounts.
    # def after_inactive_sign_up_path_for(resource)
    #   super(resource)
    # end
  end
end
