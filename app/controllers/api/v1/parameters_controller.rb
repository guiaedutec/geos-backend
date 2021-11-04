module Api
  module V1
    class ParametersController < ApiController      
      # Search for the setup parameters
      # @return [JSON]: all defined parameters
      def get_parameters
        parameter = Parameter.first
        if (!parameter.nil?)
          render json: {status: 'SUCCESS', message:'Parameters found', data:parameter},status: :ok
        else
          render json: {status: 'ERROR', message:'Parameters not found', data:nil},status: :not_found
        end
      end #def

      # Update default parameters, this work only one time
      # @return [JSON]: all defined parameters
      def save_parameters
        parameter = Parameter.first
        if (parameter.nil?) # Insert
          parameter = Parameter.new(parameter_params)
          if parameter.save
            render json: {status: 'SUCCESS', message:'Saved parameters', data:parameter},status: :ok
          else
            render json: {status: 'ERROR', message:'Parameters not saved', data:nil},status: :unprocessable_entity
          end
        else # Update
          if !parameter.setupIsDone
            if parameter.update_attributes(parameter_params)
              # Write images
              if (params[:parameter][:imgBgHome].present?)
                decodeImg(params[:parameter][:imgBgHome], "#{Rails.root}/app/assets/images/devolutive/imgBgHome.png")
              end
              if (params[:parameter][:imgLogoHeader].present?)
                decodeImg(params[:parameter][:imgLogoHeader], "#{Rails.root}/app/assets/images/devolutive/imgLogoHeader.png")
              end
              if (params[:parameter][:imgLogoHeaderSec].present?)
                decodeImg(params[:parameter][:imgLogoHeaderSec], "#{Rails.root}/app/assets/images/devolutive/imgLogoHeaderSec.png")
              end
              if (params[:parameter][:imgLogoFooter].present?)
                decodeImg(params[:parameter][:imgLogoFooter], "#{Rails.root}/app/assets/images/devolutive/imgLogoFooter.png")
              end
              if (params[:parameter][:imgLogoFooterSec].present?)
                decodeImg(params[:parameter][:imgLogoFooterSec], "#{Rails.root}/app/assets/images/devolutive/imgLogoFooterSec.png")
              end
              
              admin_user = User.where(_profile: 'admin').first
              admin_user.email = params[:parameter][:email]
              admin_user.authenticity_token = ''
              admin_user.password = admin_user.password_confirmation = params[:parameter][:adminPwd]
              admin_user.save

              if (params[:parameter][:setupIsDone].present?)
                parameter.done
              end              
              render json: {status: 'SUCCESS', message:'Updated parameters', data:params.require(:parameter)},status: :ok
            else
              render json: {status: 'ERROR', message:'Parameters not update', data:parameter.errors.messages},status: :unprocessable_entity
            end
          else
            render json: {status: 'ERROR', message:'Parameters already defined', data:nil},status: :unprocessable_entity
          end
        end
      end #def save_translation    

      # Decode Base64 imagens and save on the local disk
      def decodeImg(imgBase64, imgPath)
        i = imgBase64
        image_data = i[i.index("base64,") + "base64,".size, i.size]
        #=> iVBOR....
        image = Base64.decode64(image_data).force_encoding('utf-8')
        File.open(imgPath, "w") do |f|
          f.write(image)
        end
      end 
    private
      def parameter_params
        params.require(:parameter).permit(:imgBgHome, :imgLogoHeader, :imgLogoHeaderSec, :imgLogoFooter, :imgLogoFooter, :imgLogoFooterSec, :colorPrimary, :colorSecondary, :email, :access_token, :adminPwd, :setupIsDone) 
      end
    end
  end
end