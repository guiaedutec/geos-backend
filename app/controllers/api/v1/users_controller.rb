module Api
  module V1
    class UsersController < ApplicationController
      require 'securerandom'
      respond_to :json, :pdf
      before_action :set_user, only: [:update, :show, :destroy]
      before_action :authenticate_user!, except: [:index, :show, :create, :update]
      before_action :authenticate_admin!, except: [:index, :show,  :create, :update, :get_email_by_id, :destroy]

      def survey_response
        @user = User.find(params[:id])
        @school = @user.school
        @survey_response = @user.survey_response
        raList = ResponseAnswer.where(:user_id => @user.id, :school_id => @school.id)
        responses = Array.new
        raList.each do |resp|
          responses.push(resp)
        end
        @section_1_scores = @survey_response.position_section_scores(1, responses, @school)
        @section_2_scores = @survey_response.position_section_scores(2, responses, @school)
        @section_3_scores = @survey_response.position_section_scores(3, responses, @school)
        @section_4_scores = @survey_response.position_section_scores(4, responses, @school)
        respond_to do |format|
          format.pdf do
            render pdf: 'survey_response',
                   layout: 'pdf', orientation: 'Landscape',
                   file: "#{Rails.root}/app/views/api/v1/schools/survey_response_#{@school.state.to_s.downcase}.pdf.haml",
                   margin:  { top: 0, bottom: 0, left: 0, right: 0 }, show_as_html: params.key?('debug')
          end
        end
      end

      def index
        @user_search = UserSearch.new(search_params)

        respond_to do |format|
          format.json
        end
      end

      # List all admin_country users
      # @param user Current user
      # @return list of user with profile of admin_country
      def admin_country_list
        if current_user.admin?
          users = User.where(_profile: 'admin_country') 
          if (!users.empty?)
              render json: {status: 'SUCCESS', message:'Admin_country users found', data:users},status: :ok
          else
              render json: {status: 'ERROR', message:'Admin_country users not found', data: nil},status: :not_found
          end          
        else
          render json: {status: 'ERROR', message:'InvalidAuthenticityToken', data:nil},status: :unprocessable_entity
        end
      end

      # Get admin_country user
      # @param user Current user
      # @param admin_country user ID
      # @return user with profile of admin_country
      def get_admin_country_by_id
        if current_user.admin?
          user = User.where(_profile: 'admin_country', id: BSON::ObjectId.from_string(params[:id])).first 
          if (!user.nil?)
              render json: {status: 'SUCCESS', message:'Admin_country user found', data:user},status: :ok
          else
              render json: {status: 'ERROR', message:'Admin_country user not found', data: nil},status: :not_found
          end          
        else
          render json: {status: 'ERROR', message:'InvalidAuthenticityToken', data:nil},status: :unprocessable_entity
        end
      end

      # Get admin_country user
      # @param user Current user
      # @param admin_country user ID
      # @return user with profile of admin_country
      def delete_admin_country
        if current_user.admin?
          user = User.where(_profile: 'admin_country', id: BSON::ObjectId.from_string(params[:id])).first 
          if (!user.nil?)
              user.delete
              render json: {status: 'SUCCESS', message:'Admin_country user deleted', data: nil},status: :ok
          else
              render json: {status: 'ERROR', message:'Admin_country user not found', data: nil},status: :not_found
          end          
        else
          render json: {status: 'ERROR', message:'InvalidAuthenticityToken', data:nil},status: :unprocessable_entity
        end
      end
      
      # Treat translation for the newUserPassword object.
      def get_translation_newUserPassword
        translation = Translation.where(lang: params['lang']).first
        newUserPassword = nil
        if (!translation.nil?)
          if (!translation['Miscellaneous'].nil?)
            if !translation['Miscellaneous']['mail'].nil? 
              if !translation['Miscellaneous']['mail']['newUserPassword'].nil?
                newUserPassword = translation['Miscellaneous']['mail']['newUserPassword']
              end 
            end
          end
        end
        newUserPassword
      end

      # Insert a non-existent save_admin_country user
      # @param: access_token (user admin), country id and name, province id and name, state id and name, city id and name, type institution and name (from the institution)
      # @return [JSON]: country id and name, province id and name, state id and name, city id and name, type institution, institution id and name added
      def save_admin_country
        user = current_user
        params.permit(:name, :email, :country_name, :country_id, :phone_number, :lang)
        name = params[:name]
        email = params[:email]
        country_name = params[:country_name]
        country_id = params[:country_id]
        phone_number = params[:phone_number]
        lang = params[:lang]
        I18n.locale =  (!lang.nil?) ? lang :  I18n.default_locale
        newUserPassword = get_translation_newUserPassword

        if user.admin?
          if !newUserPassword.nil?
            if !(name.nil? || email.nil? || country_name.nil? || country_id.nil? || phone_number.nil? || lang.nil?)
              user = User.where(
                email: email
              ).first
              if (user.nil?) # Insert
                user = User.new(
                                name: name,
                                email: email,
                                country_id: BSON::ObjectId.from_string(country_id),
                                country_name: country_name,
                                phone_number: phone_number,
                                password: SecureRandom.alphanumeric(10),
                                _profile: "admin_country"
                              )
                if user.save
                  emailT = newUserPassword
                  errorMsg = nil                  
                  begin
                    UserMailer.sendt_password_new_user(user, emailT).deliver
                  rescue => ex
                    errorMsg = "User not saved. #{ex}"
                  end
                  if errorMsg.nil?
                    render json: {status: 'SUCCESS', message:'Saved admin_country user', data:user},status: :ok
                  else
                    user.delete
                    render json: {status: 'ERROR', message:errorMsg, data: nil},status: :unprocessable_entity
                  end
                else
                  # print the errors to the development log
                  Rails.logger.info(user.errors.messages.inspect)
                  render json: {status: 'ERROR', message:'User not saved', data: nil},status: :unprocessable_entity
                end
              else
                render json: {status: 'ERROR', message:'Admin_country user already exists', data: user},status: :unprocessable_entity
              end
            else
              render json: {status: 'ERROR', message:'Some params not found: name, email, country_name, country_id, phone_number, lang', data:nil},status: :not_found
            end
          else
            render json: {status: 'ERROR', message:'Translation not found for lang=' + I18n.locale.to_s + ': Translation.Miscellaneous.mail.newUserPassword', data:nil},status: :not_found
          end
        end
      end

      # Edit the name of an existing admin_country user
      # @param: access_token (user admin) 
      # @return [JSON]: user updated
      def edit_admin_country
        if current_user.admin?
          if !(params[:name].nil? || params[:email].nil? || params[:country_name].nil? || params[:country_id].nil? || params[:phone_number].nil?)
            user = User.where(id: params['id'], _profile: "admin_country").first
            if (!user.nil?)
                user.update_attributes(
                  name: params[:name],
                  email: params[:email],
                  country_id: BSON::ObjectId.from_string(params[:country_id]),
                  country_name: params[:country_name],
                  phone_number: params[:phone_number]
                )
                render json: {status: 'SUCCESS', message:'Admin_country user updated', data:user},status: :ok
            else
                render json: {status: 'ERROR', message:'Admin_country user not found', data:nil},status: :not_found
            end
          else
            render json: {status: 'ERROR', message:'Some params not found: name, email, country_name, country_id, phone_number', data:nil},status: :not_found
          end
        end
      end
      
      # List all managers of a country, only country admin can do this
      # @param user Current user
      # @param country_id The country ID
      # @param locked Lock status to filter
      # @return list of user with profile of admin_state
      def list_managers
        user = current_user
        if user.admin_country?
          if params[:locked].present?
            @users = User.where.(_profile: 'admin_state', locked: params[:locked], country_id: BSON::ObjectId.from_string(user[:country_id]))
          else
            @users = User.where(_profile: 'admin_state', country_id: BSON::ObjectId.from_string(user[:country_id]))
          end
          render json: Jbuilder.new { |json| json.array! @users, :_id, :name, :email, :locked, :responsible_name, :responsible_email, :responsible_phone_number, :manager_file, :affiliation_name}.target!
          
        elsif user.super_admin?
            if params[:country_id].present?
              if params[:locked].present?
                @users = User.where(_profile: 'admin_state', locked: params[:locked], country_id: BSON::ObjectId.from_string(params[:country_id]))  
              else
                @users = User.where(_profile: 'admin_state', country_id: BSON::ObjectId.from_string(params[:country_id]))  
              end
            else
              if params[:locked].present?
                @users = User.where(_profile: 'admin_state', locked: params[:locked])
              else
                @users = User.where(_profile: 'admin_state')
              end
            end
            render json: Jbuilder.new { |json| json.array! @users, :_id, :name, :email, :locked, :responsible_name, :responsible_email, :responsible_phone_number, :manager_file, :affiliation_name}.target!
        else
          render json: {status: 'ERROR', message:'InvalidAuthenticityToken', data:nil},status: :unprocessable_entity
        end
      end

      # Change locked field of a user, if user is locked then change to false and remove suffix from email field, otherwise locked true and add suffix
      # @param user Current user
      # @param id ID of user to change lock mode
      # @param locked
      # @return The user updated
      def change_lock
        if current_user.super_admin?
          if !params[:id].present?
            render json: {status: 'ERROR', message:'User ID is required', data:nil},status: :unprocessable_entity
          else
            user = User.find(params[:id])
            user.locked = params[:locked]
            user.save
            render json: user  
          end
        elsif current_user.admin_country?
          if !params[:id].present?
            render json: {status: 'ERROR', message:'User ID is required', data:nil},status: :unprocessable_entity
          else
            user = User.find(id: params[:id])
            if(user['country_id'] == current_user['country_id'])
              user.locked = params[:locked]
              user.save
              render json: user  
            else
              render json: {status: 'ERROR', message:'User from Different Country', data:nil},status: :unprocessable_entity
            end
          end
        else
          render json: {status: 'ERROR', message:'InvalidAuthenticityToken', data:nil},status: :unprocessable_entity
        end
      end

      def get_email_by_id
        user = User.find(params[:id])
        render json: user ? { email: user.email } : {}
      end

      def create
        puts "Params - #{params}";
        
        if !user_params
          user_params[:name] = params[:name]
        end
        @user = User.new(user_params)

        if(ActiveModel::Type::Boolean.new.cast(params['noaff']))
          @institution = Institution.find_by(name: 'Dummy Affiliation For Unaffiliated Users')
          @user.institution = @institution
          @school = School.find_by(name: 'Dummy School For Unaffiliated Users')
          @user.school = @school
          @country = Country.find_by(name: 'Dummy Country For Unaffiliated Users')
          @user.country_id = BSON::ObjectId.from_string(@country[:id])
          @user.affiliation_id = BSON::ObjectId.from_string(@institution[:id])
          @user.affiliation_name = @institution[:name]
          province = Province.find_by(name: 'Dummy Province For Unaffiliated Users')
          @user.province_id = BSON::ObjectId.from_string(province[:id])
        else
          if @user.admin_state? || @user.admin_city? || @user.teacher? || @user.principal?
            @institution = Institution.find_by(id: BSON::ObjectId.from_string(user_params[:affiliation_id]))
            @user.institution = @institution
          end
        end

        if user_params[:locked].present?
          @user.locked = user_params[:locked]
        end

        if @user.save
          render json: @user.as_json
        else
          render json: @user.errors, status: :internal_server_error
        end
      end

      def show
        render json: @user.as_json
      end

      def update
        if @user.update(user_params)
          render json: @user.as_json
        else
          render json: @user.errors, status: :internal_server_error
        end
      end

      def destroy
        if (current_user.affiliation_id != @user.affiliation_id) 
          render json: {message: 'You cannot remove users of another affiliation'}, status: :internal_server_error
        else
          @user.destroy()
          render json: @user.as_json
        end
      end

      protected

      def search_params
        user_search_params = {
            query: params[:q],
            sort_field: params[:sort],
            sort_direction: params[:sort_dir],
            page: params[:page],
            limit: params[:limit]
        }

        case params[:profile]
        when "diretores"
          user_search_params[:profile] = ['principal']
        when "professores"
          user_search_params[:profile] = ['teacher']
        else
          if current_user.admin_state?
            user_search_params[:profile] = ['admin_state', 'monitor_state', 'monitor_state_regional']
          end
        end

        if current_user.admin_state? 
          user_search_params[:affiliation_id] = current_user.affiliation_id
        end

        user_search_params
      end


      private

      def set_user
        @user = User.find(params[:id])
        if(@user.authenticity_token != params[:access_token])
          params[:access_token] = @user.authenticity_token
        end
      end

      def user_params        
        params.require(:user).permit(:profile, :name, :password, :email, :born, :affiliation_id, :country_id, :province_id, :state_id, :city_id, :school_id, :stages, :knowledges, :locked, :affiliation_name, :responsible_name, :responsible_email, :responsible_phone_number)
      end

    end
  end
end
