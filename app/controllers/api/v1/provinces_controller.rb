module Api
  module V1
    class ProvincesController < ApiController 
      before_action :authenticate_user!, only: [:save_province, :delete_province, :edit_province]
      
      # Search for a province
      # @param: province id 
      # @return [JSON]: country id and name, province id and name found
      def get_province_by_id
        province = (!params['id'].nil?) ? Province.find_by(id: params['id']) : nil
        if (!province.nil?)
            render json: {status: 'SUCCESS', message:'Province found', data:province},status: :ok
        else
            render json: {status: 'ERROR', message:'Province not found', data:nil},status: :not_found
        end  
      end #def

      # Insert a non-existent province
      # @param: access_token (user admin), country id and name, and name (from the province) 
      # @return [JSON]: country id and name, province id and name added
      def save_province
        user = current_user
        params.permit(:name, :country_name, :country_id, :id, :province_id, :province_name, :access_token, :state)
        if user.admin?
          if !(params[:name].nil? || params[:country_name].nil?)
            province = Province.where(
              name: params[:name],
              country_name: params[:country_name]).first
            if (province.nil?) # Insert
              province = Province.new(
                              name: params[:name],
                              country_id: BSON::ObjectId.from_string(params[:country_id]),
                              country_name: params[:country_name])
              if province.save
                render json: {status: 'SUCCESS', message:'Saved Province', data:province},status: :ok
              else
                render json: {status: 'ERROR', message:'Province not saved', data: nil},status: :unprocessable_entity
              end
            else
              render json: {status: 'ERROR', message:'Province already exists', data: province},status: :unprocessable_entity
            end
          end #if params[:name_province]
        elsif user.admin_country?
          if !(params[:name].nil? || params[:country_name].nil?)
            province = Province.where(
              name: params[:name],
              country_name: params[:country_name]).first
            if (province.nil?) # Insert
              if(user['country_id'] == BSON::ObjectId.from_string(params[:country_id]))
                province = Province.new(
                                name: params[:name],
                                country_id: BSON::ObjectId.from_string(params[:country_id]),
                                country_name: params[:country_name])
                if province.save
                  render json: {status: 'SUCCESS', message:'Saved Province', data:province},status: :ok
                else
                  render json: {status: 'ERROR', message:'Province not saved', data: nil},status: :unprocessable_entity
                end
              else
                render json: {status: 'ERROR', message:'Action not allowed', data: nil},status: :unprocessable_entity  
              end
            else
              render json: {status: 'ERROR', message:'Province already exists', data: province},status: :unprocessable_entity
            end
          end 
        end 
      end 

      # Delete an existing province
      # @param: access_token (user admin) and province id
      # @return [JSON]: country id and name, province id and name excluded
      def delete_province
        user = current_user
        if user.admin?
          province = (!params['id'].nil?) ? Province.find_by(id: params['id']) : nil
          if (!province.nil?)
              province.delete
              render json: {status: 'SUCCESS', message:'Province deleted', data:province},status: :ok
          else
              render json: {status: 'ERROR', message:'Province not found', data:nil},status: :not_found
          end  
        end 
      end 

      # Edit the name of an existing province
      # @param: access_token (user admin), country id and name, province id and name
      # @return [JSON]: country id and name, province id and name updated
      def edit_province
        user = current_user
        if user.admin?
          if !(params[:name].nil? || params[:country_name].nil?)
            province = Province.where(id: params[:id]).first
            if (!province.nil?)
                province.update_attributes(
                  name: params[:name],
                  country_id: BSON::ObjectId.from_string(params[:country_id][:id]),
                  country_name: params[:country_name]
                )
                render json: {status: 'SUCCESS', message:'Province updated', data:province},status: :ok
            else
                render json: {status: 'ERROR', message:'Province not found', data:nil},status: :not_found
            end   
          end 
        elsif user.admin_country?
          if !(params[:name].nil? || params[:country_name].nil?)
            province = Province.where(id: params[:id]).first
            if (!province.nil?)
                if province[:country_id] == user['country_id']
                  province.update_attributes(
                    name: params[:name],
                    country_id: BSON::ObjectId.from_string(params[:country_id][:id]),
                    country_name: params[:country_name]
                  )
                  render json: {status: 'SUCCESS', message:'Province updated', data:province},status: :ok
                else
                  render json: {status: 'ERROR', message:'Action not allowed', data:nil},status: :not_found
                end
            else
                render json: {status: 'ERROR', message:'Province not found', data:nil},status: :not_found
            end   
          end
        end
      end
    end
  end
end