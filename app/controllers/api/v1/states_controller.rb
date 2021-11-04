module Api
  module V1
    class StatesController < ApiController 
      before_action :authenticate_user!, only: [:save_state, :delete_state, :edit_state]
      
      # Search for a state
      # @param: state id 
      # @return [JSON]: country id and name, province id and name, state id and name found
      def get_state_by_id
        state = (!params['id'].nil?) ? State.find_by(id: params['id']) : nil
        if (!state.nil?)
            render json: {status: 'SUCCESS', message:'State found', data:state},status: :ok
        else
            render json: {status: 'ERROR', message:'State not found', data: nil},status: :not_found
        end  
      end 

      # Insert a non-existent state
      # @param: access_token (user admin), country id and name, province id and name, and name (from the state) 
      # @return [JSON]: country id and name, province id and name, state id and name added
      def save_state
        user = current_user
        params.permit(:name, :country_name, :province_name, :country_id, :province_id, :id, :access_token, :state)
        if user.admin?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil?)
            state = State.where(
              name: params[:name],
              country_name: params[:country_name],
              province_name: params[:province_name]).first
            if (state.nil?) # Insert
              state = State.new(
                              name: params[:name],
                              country_id: BSON::ObjectId.from_string(params[:country_id]),
                              country_name: params[:country_name],
                              province_id: BSON::ObjectId.from_string(params[:province_id]),
                              province_name: params[:province_name])
              if state.save
                render json: {status: 'SUCCESS', message:'Saved State', data:state},status: :ok
              else
                render json: {status: 'ERROR', message:'State not saved', data: nil},status: :unprocessable_entity
              end
            else
              render json: {status: 'ERROR', message:'State already exists', data: state},status: :unprocessable_entity
            end
          end 
        elsif user.admin_country?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil?)
            state = State.where(
              name: params[:name],
              country_name: params[:country_name],
              province_name: params[:province_name]).first
            if (state.nil?) # Insert
              if(user['country_id'] == BSON::ObjectId.from_string(params[:country_id]))
                state = State.new(
                                name: params[:name],
                                country_id: BSON::ObjectId.from_string(params[:country_id]),
                                country_name: params[:country_name],
                                province_id: BSON::ObjectId.from_string(params[:province_id]),
                                province_name: params[:province_name])
                if state.save
                  render json: {status: 'SUCCESS', message:'Saved State', data:state},status: :ok
                else
                  render json: {status: 'ERROR', message:'State not saved', data: nil},status: :unprocessable_entity
                end
              else
                render json: {status: 'ERROR', message:'Action not allowed', data: nil},status: :unprocessable_entity  
              end
            else
              render json: {status: 'ERROR', message:'State already exists', data: state},status: :unprocessable_entity
            end
          end 
        end 
      end 

      # Delete an existing state
      # @param: access_token (user admin) and state id
      # @return [JSON]: country id and name, province id and name, state id and name excluded
      def delete_state
        user = current_user
        if user.admin?
          state = (!params['id'].nil?) ? State.find_by(id: params['id']) : nil
          if (!state.nil?)
              state.delete
              render json: {status: 'SUCCESS', message:'State deleted', data:state},status: :ok
          else
              render json: {status: 'ERROR', message:'State not found', data:nil},status: :not_found
          end  
        end 
      end

      # Edit the name of an existing state
      # @param: access_token (user admin), country id and name, province id and name, state id and name
      # @return [JSON]: country id and name, province id and name, state id and name updated
      def edit_state
        user = current_user
        if user.admin?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil?)
            state = State.where(id: params[:id]).first
            if (!state.nil?)
                state.update_attributes(
                  name: params[:name],
                  country_id: BSON::ObjectId.from_string(params[:country_id]),
                  country_name: params[:country_name],
                  province_id: BSON::ObjectId.from_string(params[:province_id]),
                  province_name: params[:province_name]
                )
                render json: {status: 'SUCCESS', message:'State updated', data:state},status: :ok
            else
                render json: {status: 'ERROR', message:'State not found', data:nil},status: :not_found
            end
          end
        elsif user.admin_country?
          if !(params[:name].nil? || params[:country_name].nil? || params[:province_name].nil?)
            state = State.where(id: params[:id]).first
            if (!state.nil?)
              if (state[:country_id] == user['country_id'])
                  state.update_attributes(
                    name: params[:name],
                    country_id: BSON::ObjectId.from_string(params[:country_id]),
                    country_name: params[:country_name],
                    province_id: BSON::ObjectId.from_string(params[:province_id]),
                    province_name: params[:province_name]
                  )
                  render json: {status: 'SUCCESS', message:'State updated', data:state},status: :ok
              else
                render json: {status: 'ERROR', message:'Action not allowed', data:nil},status: :not_found
              end
            else
                render json: {status: 'ERROR', message:'State not found', data:nil},status: :not_found
            end
          end
        end
      end

    end
  end
end