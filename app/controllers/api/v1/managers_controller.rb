module Api
  module V1
    class ManagersController < ApiController
      respond_to :json
      before_action :set_manager, only: [:update, :show, :destroy]
      before_action :authenticate_admin!, except: [:index, :show, :valid_principal]

      def upload_files

        user = current_user
        if !params[:file].nil?
          img = ManagerFile.new
          img.file_upload = params[:file]
          img.affiliation_id = user.institution._id
          img.user_id = user._id
          img.save
        end
        render json: { :upload => img }.to_json
      end

      def remove_file
        user = current_user

        puts 'delete ' + params[:_id]

        managerFile = ManagerFile.where(:_id => params[:_id]).first

        ret =  managerFile.destroy()
        render json: { :valid => ret }.to_json
      end

      def index
        @manager_search = ManagerSearch.new(search_params)
        respond_to do |format|
          format.json
        end
      end

      def create
        @manager = Manager.new(manager_params)

        user = current_user

        if user.admin_state?
          @manager.type = "Estadual"
          @manager.institution = Institution.find_by(id: BSON::ObjectId.from_string(user[:affiliation_id]))
        end

        if @manager.save
          render json: @manager.as_json
        else
          render json: @manager.errors, status: :internal_server_error
        end

      end

      def show
        render json: @manager.as_json
      end

      def update

        if current_user.admin_state?
          @manager.type = "Estadual"
          @manager.state = current_user.state
        end

        if current_user.admin_city?
          @manager.type = "Municipal"
          @manager.state = current_user.state
          @manager.city = current_user.city
        end

        if @manager.update(manager_params)
          render json: @manager.as_json
        else
          render json: @manager.errors, status: :internal_server_error
        end
      end

      def destroy
        if @manager.destroy()
          render json: @manager.as_json
        else
          render json: @manager.errors, status: :internal_server_error
        end
      end

      def valid_principal

        valid = false
        
        if params[:schoolId].present?
          school = School.where(:_id => params[:schoolId]).first

          if !school.nil?
            if !school.manager_id.nil? and school.manager
              if school.manager.email == params[:email]
                valid = true
              else
                valid = false
              end
            else
              valid = true
            end
          end
        else
          valid = true
        end

         respond_to do |format|
            format.json {
              render :json => {:valid => valid }.to_json, :status => 200
            }
         end
       end

      protected

      def search_params
        user = current_user

        manager_search_params = {
            query: params[:q],
            sort_field: params[:sort],
            sort_direction: params[:sort_dir],
            page: params[:page],
            limit: params[:limit],
            institution: user.affiliation_id
        }
        manager_search_params
      end

      private

      def set_manager
        @manager = Manager.find(params[:id])
      end

      def manager_params
        params.require(:manager).permit(:name, :email, :phone)
      end
    end
  end
end
