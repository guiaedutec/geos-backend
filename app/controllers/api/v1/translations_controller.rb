module Api
  module V1
    class TranslationsController < ApiController
      before_action :authenticate_user!, only: [:save_translation]
      
      # Search for the translated attributes of a language
      # @param: lang
      # @return [JSON]: status, message and data (with all the attributes translated)
      def get_translation_by_lang
        translation = Translation.where(lang: params['lang'])
        if (!translation.nil?)
          render json: {status: 'SUCCESS', message:'Translation found', data:translation},status: :ok
        else
          render json: {status: 'ERROR', message:'Translation not found', data:nil},status: :not_found
        end
      end

      # Insert a new language or edit an existing language
      # @param: access_token (user admin) and lang
      # @return [JSON]: status, message and data (with all attributes translated)
      def save_translation
        user = current_user
        if user.admin?
          translation = Translation.where(lang: params[:translation][:lang]).first
          if (translation.nil?) # Insert
            translation = Translation.new(translations_params)
            if translation.save
              render json: {status: 'SUCCESS', message:'Saved translation', data:translation},status: :ok
            else
              render json: {status: 'ERROR', message:'Translation not saved', data:nil},status: :unprocessable_entity
            end
          else # Update
            if translation.update_attributes(translations_params)
              render json: {status: 'SUCCESS', message:'Updated translate', data:params.require(:translation)},status: :ok
            else
              render json: {status: 'ERROR', message:'Translate not update', data:nil},status: :unprocessable_entity
            end
          end
        end
      end
      private
      def translations_params
        params.require(:translation).permit(translation: params[:translation].keys)
      end    
    end
  end
end