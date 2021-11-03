module Users
  class PasswordsController < Devise::PasswordsController
    respond_to :json, :html
    skip_before_action :verify_authenticity_token, only: [:update]
    layout 'admin'

    # GET /resource/password/new
    # def new
    #   super
    # end

    # POST /resource/password
    def create
      user = User.find_by(email: params['user']['email'])
      @emailT = translation_email
      UserMailer.send_reset_password_instructions(user, @emailT['resetPassword']).deliver
      render json: {}
    end
    # confirmation_instructions
    def confirmation_instructions
      user = User.find_by(email: params['user']['email'])
      @emailT = translation_email
      UserMailer.send_confirmation_instructions(user, @emailT['confirmationInstructions']).deliver
      render json: {}
    end
    # sendT_invite
    def sendt_invite
      user = User.find_by(email: params['user']['email'])
      @emailT = translation_email
      UserMailer.sendt_invite(user, @emailT['sendtInvite']).deliver
      render json: {}
    end

    # sendt_password_new_user
    def sendt_password_new_user(email)
      user = User.find_by(email: email)
      @emailT = translation_email
      UserMailer.sendt_invite(user, @emailT['newUserPassword']).deliver
      render json: {}
    end

    # GET /resource/password/edit?reset_password_token=abcdef
    # def edit
    #   super
    # end

    # PUT /resource/password
    def update
      self.resource = resource_class.reset_password_by_token(resource_params)
      yield resource if block_given?

      if resource.errors.empty?
        resource.unlock_access! if unlockable?(resource)
        if Devise.sign_in_after_reset_password
          flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
          set_flash_message!(:notice, flash_message)
          sign_in(resource_name, resource)
        else
          set_flash_message!(:notice, :updated_not_active)
        end
        respond_to do |format|
          format.json { render json: resource }
          format.html { respond_with resource, location: after_resetting_password_path_for(resource) }
        end
      else
        set_minimum_password_length
        respond_with resource
      end
    end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
    def translation_email
      @translations = get_translation_by_lang
      lang_parsed = JSON.parse(@translations)
      @data = lang_parsed['data']
      @mailT = @data[0]['Miscellaneous']['mail']

    end

    protected
    def get_translation_by_lang
      translationController = Api::V1::TranslationsController.new
      translationController.request = request
      translationController.response = response
      translationController.get_translation_by_lang
    end 
   
    private
    def user_email
      params.require(:user).permit(:email)
    end

    def custom_flash_notice
      "Foi enviado um email para '#{user_email}' com informações para alteração de senha"
    end
  end
  
end
