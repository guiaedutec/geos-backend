module Api
  module V1
    class LanguagesController < ApiController

      before_action :authenticate_user!, only: [:save_language]

      def get_langs_translation
        langs = Language.all.pluck(:lang).uniq
        if (!langs.empty?)
          render json: {status: 'SUCCESS', message:'Langs found', data:langs},status: :ok
        else
          render json: {status: 'ERROR', message:'Langs not found', data: nil},status: :not_found
        end  
      end

      def get_langs
        langs = Language.where(:display => true)
        if (!langs.empty?)
          render json: {status: 'SUCCESS', message:'Langs found', data:langs},status: :ok
        else
          render json: {status: 'ERROR', message:'Langs not found', data:langs},status: :not_found
        end
      end
    end
  end
end