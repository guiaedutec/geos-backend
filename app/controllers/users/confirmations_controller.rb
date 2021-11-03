module Users
  class ConfirmationsController < Devise::ConfirmationsController
    layout 'admin'

    # GET /resource/confirmation/new
    # def new
    #   super
    # end

    # POST /resource/confirmation
    # def create
    #   super
    # end

    # GET /resource/confirmation?confirmation_token=abcdef
    # def show
    #   super
    # end

    # protected

    # The path used after resending confirmation instructions.
    # def after_resending_confirmation_instructions_path_for(resource_name)
    #   super(resource_name)
    # end

    def after_confirmation_path_for(_resource_name, resource)
      resource.admin? ? admin_path : "#{ENV['FRONTEND_URL']}/recursos?access_token=#{resource.authenticity_token}"
    end
  end
end
