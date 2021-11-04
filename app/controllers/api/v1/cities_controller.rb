module Api
  module V1
    class CitiesController < ApiController 
      before_action :authenticate_user!, only: [:save_city, :delete_city, :edit_city]
      
      # Search for a city
      # @param: city id 
      # @return [JSON]: country id and name, province id and name, state id and name, city id and name found
      def get_city_by_id
        city = (!params['id'].nil?) ? City.find_by(id: params['id']) : nil
        if (!city.nil?)
            render json: {status: 'SUCCESS', message:'City found', data:city},status: :ok
        else
            render json: {status: 'ERROR', message:'City not found', data:city},status: :not_found
        end  
      end 

      # Insert a non-existent city
      # @param: access_token (user admin), country id and name, province id and name, state id and name, and name (from the city) 
      # @return [JSON]: country id and name, province id and name, state id and name, city id and name added
      def save_city
        user = current_user
        params.permit(:name, :country_name, :province_name, :state_name, :country_id, :province_id, :state_id, :id, :name, :access_token, :state)
        if user.admin?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil? || params[:state_name].nil?)
            city = City.where(
              name: params[:name],
              country_name: params[:country_name],
              province_name: params[:province_name],
              state_name: params[:state_name]).first
            if (city.nil?) # Insert
              city = City.new(
                              name: params[:name],
                              country_id: BSON::ObjectId.from_string(params[:country_id]),
                              country_name: params[:country_name],
                              province_id: BSON::ObjectId.from_string(params[:province_id]),
                              province_name: params[:province_name],
                              state_id: BSON::ObjectId.from_string(params[:state_id]),
                              state_name: params[:state_name])
              if city.save
                render json: {status: 'SUCCESS', message:'Saved City', data:city},status: :ok
              else
                render json: {status: 'ERROR', message:'City not saved', data: nil},status: :unprocessable_entity
              end
            else
              render json: {status: 'ERROR', message:'City already exists', data: city},status: :unprocessable_entity
            end
          end 
        elsif user.admin_country?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil? || params[:state_name].nil?)
            city = City.where(
              name: params[:name],
              country_name: params[:country_name],
              province_name: params[:province_name],
              state_name: params[:state_name]).first
            if (city.nil?) # Insert
              if (user['country_id'] == BSON::ObjectId.from_string(params[:country_id]))
                city = City.new(
                                name: params[:name],
                                country_id: BSON::ObjectId.from_string(params[:country_id]),
                                country_name: params[:country_name],
                                province_id: BSON::ObjectId.from_string(params[:province_id]),
                                province_name: params[:province_name],
                                state_id: BSON::ObjectId.from_string(params[:state_id]),
                                state_name: params[:state_name])
                if city.save
                  render json: {status: 'SUCCESS', message:'Saved City', data:city},status: :ok
                else
                  render json: {status: 'ERROR', message:'City not saved', data: nil},status: :unprocessable_entity
                end
              else
                render json: {status: 'ERROR', message:'Action not allowed', data: nil},status: :unprocessable_entity  
              end
            else
              render json: {status: 'ERROR', message:'City already exists', data: city},status: :unprocessable_entity
            end
          end 
        end 
      end 

      # Delete an existing city
      # @param: access_token (user admin) and city id
      # @return [JSON]: country id and name, province id and name, state id and name, city id and name excluded
      def delete_city
        user = current_user
        if user.admin?
          city = (!params['id'].nil?) ? City.find_by(id: params['id']) : nil
          if (!city.nil?)
              city.delete
              render json: {status: 'SUCCESS', message:'City deleted', data:city},status: :ok
          else
              render json: {status: 'ERROR', message:'City not found', data:nil},status: :not_found
          end  
        end #if-user.admin?
      end #def

      # Edit the name of an existing city
      # @param: access_token (user admin), country id and name, province id and name, state id and name, city id and name 
      # @return [JSON]: country id and name, province id and name, state id and name, city id and name updated
      def edit_city
        user = current_user
        if user.admin?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil? || params[:state_name].nil?)
            city = City.where(id: params[:id]).first
            if (!city.nil?)
                city.update_attributes(
                  name: params[:name],
                  country_id: BSON::ObjectId.from_string(params[:country_id]),
                  country_name: params[:country_name],
                  province_id: BSON::ObjectId.from_string(params[:province_id]),
                  province_name: params[:province_name],
                  state_id: BSON::ObjectId.from_string(params[:state_id]),
                  state_name: params[:state_name]
                )
                render json: {status: 'SUCCESS', message:'City updated', data:city},status: :ok
            else
                render json: {status: 'ERROR', message:'City not found', data:nil},status: :not_found
            end   
          end 
        elsif user.admin_country?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil? || params[:state_name].nil?)
            city = City.where(id: params[:id]).first
            if (!city.nil?)
                if (city[:country_id] == user['country_id'])
                  city.update_attributes(
                    name: params[:name],
                    country_id: BSON::ObjectId.from_string(params[:country_id]),
                    country_name: params[:country_name],
                    province_id: BSON::ObjectId.from_string(params[:province_id]),
                    province_name: params[:province_name],
                    state_id: BSON::ObjectId.from_string(params[:state_id]),
                    state_name: params[:state_name]
                  )
                  render json: {status: 'SUCCESS', message:'City updated', data:city},status: :ok
                else
                  render json: {status: 'ERROR', message:'Action not allowed', data:nil},status: :not_found
                end
            else
                render json: {status: 'ERROR', message:'City not found', data:nil},status: :not_found
            end 
          end
        end 
      end 
    end 
  end
end