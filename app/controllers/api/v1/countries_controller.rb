module Api
    module V1
      class CountriesController < ApiController 
        before_action :authenticate_user!, only: [:save_country, :delete_country, :edit_country]
        
        # Search for a country
        # @param: country id 
        # @return [JSON]: country id and name found
        def get_country_by_id
          countries = (!params['id'].nil?) ? Country.find_by(id: params['id']) : nil
          if (!countries.nil?)
              render json: {status: 'SUCCESS', message:'Countries found', data:countries},status: :ok
          else
              render json: {status: 'ERROR', message:'Countries not found', data:countries},status: :not_found
          end  
        end 

        # Insert a non-existent country
        # @param: access_token (user admin) and name (from the country)
        # @return [JSON]: country id and name added
        def save_country
          user = current_user
          if user.admin?
            if (!params[:name].nil?)
              country = Country.find_by(name: params[:name])
              if country.nil?
                country = Country.new(name: params[:name], geo_structure_level1_name: params['geo_structure_level1_name'],
                                      geo_structure_level2_name: params['geo_structure_level2_name'], geo_structure_level3_name: params['geo_structure_level3_name'],
                                      geo_structure_level4_name: params['geo_structure_level4_name'])
                if country.save
                  render json: {status: 'SUCCESS', message:'Saved country', data:country},status: :ok
                else
                  render json: {status: 'ERROR', message:'Country not saved', data: nil},status: :unprocessable_entity
                end
              else
                render json: {status: 'ERROR', message:'Country already exists', data: country},status: :unprocessable_entity
              end 
            end
          end
        end

        # Delete an existing country
        # @param: access_token (user admin) and country id
        # @return [JSON]: country id and name excluded
        def delete_country
          user = current_user
          if user.admin?
            country = (!params['id'].nil?) ? Country.find_by(id: params['id']) : nil
            if (!country.nil?)
                delete_country_cascade(params['id'])
                render json: {status: 'SUCCESS', message:'Country deleted', data:country},status: :ok
            else
                render json: {status: 'ERROR', message:'Country not found', data:nil},status: :not_found
            end  
          end
        end

        # Edit the name of an existing country
        # @param: access_token (user admin), country id and name 
        # @return [JSON]: country id and name updated
        def edit_country
          user = current_user
          if user.admin?
            country = (!params['id'].nil?) ? Country.find_by(id: params['id']) : nil
            if (!country.nil?)
                country.update_attributes({
                                          name: params['name'],
                                          geo_structure_level1_name: params['geo_structure_level1_name'],
                                          geo_structure_level2_name: params['geo_structure_level2_name'],
                                          geo_structure_level3_name: params['geo_structure_level3_name'],
                                          geo_structure_level4_name: params['geo_structure_level4_name']
                                          })
                render json: {status: 'SUCCESS', message:'Country updated', data:country},status: :ok
            else
                render json: {status: 'ERROR', message:'Country not found', data:nil},status: :not_found
            end
          elsif user.admin_country?
            country = (!params['id'].nil?) ? Country.find_by(id: params['id']) : nil
            if (!country.nil?)
                if(country['id'] == user['country_id'])
                  country.update_attributes({
                                            name: params['name'],
                                            geo_structure_level1_name: params['geo_structure_level1_name'],
                                            geo_structure_level2_name: params['geo_structure_level2_name'],
                                            geo_structure_level3_name: params['geo_structure_level3_name'],
                                            geo_structure_level4_name: params['geo_structure_level4_name']
                                            })
                  render json: {status: 'SUCCESS', message:'Country updated', data:country},status: :ok
                else
                  render json: {status: 'ERROR', message:'Action not allowed', data:nil},status: :not_found
                end
            else
                render json: {status: 'ERROR', message:'Country not found', data:nil},status: :not_found
            end
          end
        end


      end
    end
  end