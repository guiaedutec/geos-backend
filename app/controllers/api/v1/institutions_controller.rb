module Api
  module V1
    class InstitutionsController < ApiController
      before_action :authenticate_user!, only: [:save_institution, :delete_institution, :edit_institution]
      
      # Search for a institution
      def get_institution_by_id
        institution = (!params['id'].nil?) ? Institution.find_by(id: params['id']) : nil
        if (!institution.nil?)
            render json: {status: 'SUCCESS', message:'Institution found', data:institution},status: :ok
        else
            render json: {status: 'ERROR', message:'Institution not found', data: nil},status: :not_found
        end  
      end

      # Insert a non-existent institution
      def save_institution
        user = current_user
        params.permit(:name, :country_name, :province_name, :state_name, :country_id, :province_id, :state_id, :city_id, :city_name, :type_institution, :access_token)
        if user.admin?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil? || params[:state_name].nil?)
            # Verificar se a instituição já está no banco
            institution = Institution.where(
              name: params[:name],
              country_name: params[:country_name]
            ).first
            if (institution.nil?) # Insert
              institution = Institution.new(
                              name: params[:name],
                              country_id: BSON::ObjectId.from_string(params[:country_id]),
                              country_name: params[:country_name],
                              province_id: BSON::ObjectId.from_string(params[:province_id]),
                              province_name: params[:province_name],
                              state_id: BSON::ObjectId.from_string(params[:state_id]),
                              state_name: params[:state_name],
                              city_id: !(params[:city_id].nil?) ? BSON::ObjectId.from_string(params[:city_id]) : nil,
                              city_name: !(params[:city_name].nil?) ? params[:city_name] : nil,
                              type_institution: params[:type_institution]
                            )
              if institution.save
                render json: {status: 'SUCCESS', message:'Saved institution', data:institution},status: :ok
              else
                render json: {status: 'ERROR', message:'Institution not saved', data: nil},status: :unprocessable_entity
              end
            else
              render json: {status: 'ERROR', message:'Institution already exists', data: institution},status: :unprocessable_entity
            end
          end 
        elsif user.admin_country?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil? || params[:state_name].nil?)
            institution = Institution.where(
              name: params[:name],
              country_name: params[:country_name]
            ).first
            if (institution.nil?) # Insert
              if(user['country_id'] == BSON::ObjectId.from_string(params[:country_id]))
                institution = Institution.new(
                                name: params[:name],
                                country_id: BSON::ObjectId.from_string(params[:country_id]),
                                country_name: params[:country_name],
                                province_id: BSON::ObjectId.from_string(params[:province_id]),
                                province_name: params[:province_name],
                                state_id: BSON::ObjectId.from_string(params[:state_id]),
                                state_name: params[:state_name],
                                city_id: !(params[:city_id].nil?) ? BSON::ObjectId.from_string(params[:city_id]) : nil,
                                city_name: !(params[:city_name].nil?) ? params[:city_name] : nil,
                                type_institution: params[:type_institution]
                              )
                if institution.save
                  render json: {status: 'SUCCESS', message:'Saved institution', data:institution},status: :ok
                else
                  render json: {status: 'ERROR', message:'Institution not saved', data: nil},status: :unprocessable_entity
                end
              else
                render json: {status: 'ERROR', message:'Action not allowed', data: nil},status: :unprocessable_entity  
              end
            else
              render json: {status: 'ERROR', message:'Institution already exists', data: institution},status: :unprocessable_entity
            end
          end 
        end 
      end 

      # Delete an existing institution
      def delete_institution
        user = current_user
        if user.admin?
          institution = (!params['id'].nil?) ? Institution.find_by(id: params['id']) : nil
          if (!institution.nil?)
            institution_id = institution.id
            delete_user_cascade_by_affiliation(institution_id)
            delete_affiliation_cascade(institution_id)
            render json: {status: 'SUCCESS', message:'Institution deleted', data:institution},status: :ok
          else
            render json: {status: 'ERROR', message:'Institution not found', data: nil},status: :not_found
          end
        elsif user.admin_country?
          institution = (!params['id'].nil?) ? Institution.find_by(id: params['id']) : nil
          if (!institution.nil?)

            if(user['country_id'] == institution[:country_id])
              institution_id = institution.id
              delete_user_cascade_by_affiliation(institution_id)
              delete_affiliation_cascade(institution_id)
              render json: {status: 'SUCCESS', message:'Institution deleted', data:institution},status: :ok
            else
              render json: {status: 'ERROR', message:'Action not allowed', data: nil},status: :not_found
            end
          else
            render json: {status: 'ERROR', message:'Institution not found', data: nil},status: :not_found
          end
        end 
      end 

      def edit_institution
        user = current_user
        if user.admin?
          if !(params[:name].nil? || 
              params[:country_name].nil?
            )
            institution = Institution.where(id: params[:id]).first

            if (!institution.nil?)
                institution.update_attributes(
                  name: params[:name],
                  country_id: BSON::ObjectId.from_string(params[:country_id]),
                  country_name: params[:country_name],
                  province_id: BSON::ObjectId.from_string(params[:province_id]),
                  province_name: params[:province_name],
                  state_id: BSON::ObjectId.from_string(params[:state_id]),
                  state_name: params[:state_name],
                  city_id: !(params[:city_id].nil?) ? BSON::ObjectId.from_string(params[:city_id]) : nil,
                  city_name: !(params[:city_name].nil?) ? params[:city_name] : nil,
                  type_institution: params[:type_institution]
                )
                render json: {status: 'SUCCESS', message:'Institution updated', data:institution},status: :ok
            else
                render json: {status: 'ERROR', message:'Institution not found', data:nil},status: :not_found
            end
          end 
        elsif user.admin_country?
          if !(params[:name].nil? || params[:country_name].nil?)
            institution = Institution.where(id: params[:id]).first

            if (!institution.nil?)
              institution.update_attributes(
                name: params[:name],
                country_id: BSON::ObjectId.from_string(params[:country_id]),
                country_name: params[:country_name],
                province_id: BSON::ObjectId.from_string(params[:province_id]),
                province_name: params[:province_name],
                state_id: BSON::ObjectId.from_string(params[:state_id]),
                state_name: params[:state_name],
                city_id: !(params[:city_id].nil?) ? BSON::ObjectId.from_string(params[:city_id]) : nil,
                city_name: !(params[:city_name].nil?) ? params[:city_name] : nil,
                type_institution: params[:type_institution]
              )
              render json: {status: 'SUCCESS', message:'Institution updated', data:institution},status: :ok
            else
              render json: {status: 'ERROR', message:'Institution not found', data:nil},status: :not_found
            end 
          end
        end         
      end
    end
  end
end