module Api
  module V1
    class SchoolsController < ApiController
      respond_to :json, :pdf
      before_action :set_school, only: [:survey_response, :update, :show, :destroy]
      before_action :authenticate_user!, except: [:survey_response, :survey_example, :index, :show, :user_school, :has_answereds, :has_samples, :user_answered, :get_school_by_id]
      before_action :authenticate_admin!, except: [:edit_school, :survey_response, :survey_example, :index, :show, :update, :user_school, :has_answereds, :has_samples, :user_answered, :get_school_by_id]

      # Search for a school
      def get_school_by_id
        school = (!params['id'].nil?) ? School.includes(:school_infra).find_by(id: params['id']) : nil
        if (!school.nil?)
            render json: {status: 'SUCCESS', message:'School found', data:school},status: :ok
        else
            render json: {status: 'ERROR', message:'School not found', data: nil},status: :not_found
        end  
      end 

      # Insert a non-existent school
      def save_school
        user = current_user
        if user.admin? || user.admin_state?
          if !(params[:school][:name].nil? || 
                params[:school][:affiliation_name].nil? || 
                params[:school][:country_name].nil? || 
                params[:school][:province_name].nil? || 
                params[:school][:state_name].nil? || 
                params[:school][:city_name].nil?)
            school = School.where(
              name: params[:school][:name],
              affiliation_name: params[:school][:affiliation_name],
              country_name: params[:school][:country_name],
              province_name: params[:school][:province_name],
              state_name: params[:school][:state_name],
              city_name: !(params[:school][:city_name].nil?) ? params[:school][:city_name] : nil).first
            if (school.nil?) # Insert
              if user.admin_state? && user.affiliation_id != BSON::ObjectId.from_string(params[:school][:affiliation_id]) # Perfil gestor
                render json: {status: 'ERROR', message:'Manager profile: affiliation not allowed.', data: nil},status: :unprocessable_entity
              else
                school = School.new(school_params)
                if school.save
                  render json: {status: 'SUCCESS', message:'Saved school', data:school},status: :ok
                else
                  render json: {status: 'ERROR', message:'School not saved', data: nil},status: :unprocessable_entity
                end
              end
            else
              render json: {status: 'ERROR', message:'School already exists', data: school},status: :unprocessable_entity
            end
          else
            render json: {status: 'ERROR', message:'Mandatory params: name, affiliation_name, country_name, province_name, state_name, and city_name', data: nil},status: :unprocessable_entity
          end 
        end 
      end 

      # Delete an existing school
      def delete_school
        user = current_user
        if user.admin?
          school = (!params['id'].nil?) ? School.find_by(id: params['id']) : nil
          if (!school.nil?)
              delete_school_cascade(params['id'])
              render json: {status: 'SUCCESS', message:'School deleted', data:school},status: :ok
          else
              render json: {status: 'ERROR', message:'School not found', data: nil},status: :not_found
          end  
        elsif user.admin_country?
          school = (!params['id'].nil?) ? School.find_by(id: params['id']) : nil
          if (!school.nil? && school.country_id == user.country_id)
              delete_school_cascade(params['id'])
              render json: {status: 'SUCCESS', message:'School deleted', data:school},status: :ok
          else
              render json: {status: 'ERROR', message:'School not found', data: nil},status: :not_found
          end  
        end
      end 

      # Edit the name of an existing school
      def edit_school
        user = current_user
        if user.admin? || user.principal?
          if !params[:id].nil?
            school = School.where(id: params[:id]).first
            if (!school.nil?)
                school.update_attributes(school_params)
                render json: {status: 'SUCCESS', message:'School updated', data:school},status: :ok
            else
                render json: {status: 'ERROR', message:'School not found', data:nil},status: :not_found
            end 
          end
        end
      end
      
      def upload_geographical_csv
        user = current_user
        if user.admin? || user.admin_country?
          csv_file = params[:file]
          # Country
          CSV.foreach(csv_file.path, encoding: "UTF-8", headers: true).with_index(1) do |row, row_number| 
            country = Country.where(name: row['level_1_name']&.strip).first
            if (country.nil?) # Insert
              country = Country.new({name: row['level_1_name']&.strip}) 
              if !country.name.nil?
                country.save!
                Rails.logger.info(country.errors.messages.inspect)
              end
            end
            
          end 

          # Province         
          CSV.foreach(csv_file.path, encoding: "UTF-8", headers: true).with_index(1) do |row, row_number| 
            country = Country.where(name: row['level_1_name']&.strip).first
            if !country.nil?
              province = Province.where(name: row['level_2_name']&.strip, country_id: BSON::ObjectId.from_string(country.id)).first
            end
            if (province.nil?) # Insert
              if !country.nil?
                province = Province.new({name: row['level_2_name']&.strip, country_id: BSON::ObjectId.from_string(country.id), country_name: country.name})
              end
              if !province.nil?
                province.save!
              end
            end 
          end 
          
          # State
          CSV.foreach(csv_file.path, encoding: "UTF-8", headers: true).with_index(1) do |row, row_number| 
            if !(row['level_3_name'].nil?)
              country = Country.where(name: row['level_1_name']&.strip).first
              if !country.nil?
                province = Province.where(name: row['level_2_name']&.strip, country_id: BSON::ObjectId.from_string(country.id)).first
              end            
              if !province.nil?
                state = State.where(name: row['level_3_name']&.strip, 
                                    country_id: BSON::ObjectId.from_string(country.id),
                                    province_id: BSON::ObjectId.from_string(province.id)).first
              end
              if (state.nil?) # Insert
                if !country.nil? || !province.nil?
                    state = State.new({name: row['level_3_name']&.strip, 
                                      country_id: BSON::ObjectId.from_string(country.id), country_name: country.name,
                                      province_id: BSON::ObjectId.from_string(province.id), province_name: province.name})
                end  
                if !state.nil?
                  state.save!
                end
              end 
            end
          end

          # City
          CSV.foreach(csv_file.path, encoding: "UTF-8", headers: true).with_index(1) do |row, row_number| 
            country = Country.where(name: row['level_1_name']&.strip).first
            if !country.nil?
              province = Province.where(name: row['level_2_name']&.strip, country_id: BSON::ObjectId.from_string(country.id)).first
            end
            if !province.nil?
              state = State.where(name: row['level_3_name']&.strip, 
                                  country_id: BSON::ObjectId.from_string(country.id),
                                  province_id: BSON::ObjectId.from_string(province.id)).first
            end
            if !state.nil?
              if !(row['level_4_name'].nil?)
                city = City.where(
                  name: !(row['level_4_name'].nil?) ? row['level_4_name']&.strip : "", 
                  country_id: BSON::ObjectId.from_string(country.id),
                  province_id: BSON::ObjectId.from_string(province.id),
                  state_id: BSON::ObjectId.from_string(state.id)).first
              end
            end
            if (city.nil?) && !row['level_4_name'].nil? # Insert
              if !country.nil? || !province.nil? || !state.nil?
                  city = City.new({
                    name: row['level_4_name']&.strip,  
                    country_id: BSON::ObjectId.from_string(country.id), 
                    country_name: country.name,
                    province_id: BSON::ObjectId.from_string(province.id), 
                    province_name: province.name,
                    state_id: BSON::ObjectId.from_string(state.id), 
                    state_name: state.name})
              end  
              if !city.nil?
                city.save!
              end
            end
          end          
        end
      end

      def upload_institution_csv
        user = current_user
        if user.admin? || user.admin_country?
          csv_file = params[:file]
          CSV.foreach(csv_file.path, encoding: "UTF-8", headers: true).with_index(1) do |row, row_number| 
            country = Country.where(name: row['level_1_name']&.strip).first
            if !country.nil?
              province = Province.where(name: row['level_2_name']&.strip, country_id: BSON::ObjectId.from_string(country.id)).first
            end
            if !province.nil?
              state = State.where(name: row['level_3_name']&.strip, 
                                  country_id: BSON::ObjectId.from_string(country.id),
                                  province_id: BSON::ObjectId.from_string(province.id)).first
            end
            if !state.nil?
              city = City.where(
                name: !(row['level_4_name'].nil?) ? row['level_4_name']&.strip : "", 
                country_id: BSON::ObjectId.from_string(country.id),
                province_id: BSON::ObjectId.from_string(province.id),
                state_id: BSON::ObjectId.from_string(state.id)).first
            end
            
            institution = Institution.where(name: row['affiliation']&.strip,
                                            country_id: BSON::ObjectId.from_string(country.id)                                            
                                          ).first
            if (institution.nil?) # Insert
              institution = Institution.new(name: row['affiliation']&.strip,
                                              country_id: BSON::ObjectId.from_string(country.id),
                                              country_name: row['level_1_name']&.strip,
                                              type_institution: row[0]&.strip
                                            )
              institution.save!
            else
              institution.update_attributes!(
                                      name: row['affiliation']&.strip,
                                      country_id: BSON::ObjectId.from_string(country.id),
                                      country_name: row['level_1_name']&.strip,
                                      type_institution: row[0]&.strip
                                    )
            end
          end
        end
      end

      def upload_school_csv
        user = current_user
        if user.admin?
          header_error = []
          csv_file = params[:file]
          header = CSV.open(csv_file.path, encoding: 'bom|utf-8', &:readline)
          if header != ["type", "affiliation", "school_name", "level_1_name", "level_2_name", "level_3_name", "level_4_name", "unique_code"]
            header_error.push("The CSV structure must have: type,affiliation,school_name,level_1_name,level_2_name,level_3_name,level_4_name,unique_code")
          end
          if !header_error.empty?
            render json: {status: 'ERROR', message:'Invalid CSV structure.', data: {school_name: nil, line: 1, errors: header_error}},status: :unprocessable_entity
          else
            upload_geographical_csv
            upload_institution_csv
            school_error = []
            csv_file = params[:file]
            CSV.foreach(csv_file.path, encoding: "UTF-8", headers: true).with_index(1) do |row, row_number|             
              errors = []
              if row['school_name'].nil?
                errors.push("School name not found.")
              end
              if row['affiliation'].nil?
                errors.push("Instituition not found.")
              end
              if row['level_1_name'].nil?
                errors.push("Geographic structure (country) not found.")
              end
              if row['level_2_name'].nil?
                errors.push("Geographic structure (level 2) not found.")
              end
              if !errors.empty?
                school_error.push({school_name: row['school_name']&.strip, line: row_number, errors: errors})
              else
                country = Country.where(name: row['level_1_name']&.strip).first
                if !country.nil?
                  province = Province.where(name: row['level_2_name']&.strip, country_id: BSON::ObjectId.from_string(country.id)).first
                end
                if !province.nil?
                  state = State.where(name: row['level_3_name']&.strip, 
                                      country_id: BSON::ObjectId.from_string(country.id),
                                      province_id: BSON::ObjectId.from_string(province.id)).first
                end
                if !state.nil?
                  city = City.where(name: !row['level_4_name'].nil? ? row['level_4_name']&.strip : nil, 
                                    country_id: BSON::ObjectId.from_string(country.id),
                                    province_id: BSON::ObjectId.from_string(province.id),
                                    state_id: BSON::ObjectId.from_string(state.id)).first
                end
                institution = Institution.where(
                  name: row['affiliation']&.strip,
                  country_id: BSON::ObjectId.from_string(country.id)
                ).first

                unique_code = row['unique_code']&.strip
                school = nil
                if (!unique_code.nil?) && (unique_code != "")
                  school = School.where(
                    inep_code: unique_code,
                    affiliation_name: row['affiliation']&.strip,
                    country_id: BSON::ObjectId.from_string(country.id),
                    province_id: BSON::ObjectId.from_string(province.id),
                    state_id: !(state.nil?) ? BSON::ObjectId.from_string(state.id) : nil,
                    city_id: !(city.nil?) ? BSON::ObjectId.from_string(city.id) : nil,).first
                end
                
                if (school.nil?)
                  school = School.where(
                    name: row['school_name']&.strip,
                    affiliation_name: row['affiliation']&.strip,
                    country_id: BSON::ObjectId.from_string(country.id),
                    province_id: BSON::ObjectId.from_string(province.id),
                    state_id: !(state.nil?) ? BSON::ObjectId.from_string(state.id) : nil,
                    city_id: !(city.nil?) ? BSON::ObjectId.from_string(city.id) : nil,).first
                end
                  
                if (school.nil?) # Insert
                  school = School.new(
                    name: row['school_name']&.strip,
                    affiliation_id: BSON::ObjectId.from_string(institution.id),
                    affiliation_name: institution.name,                 
                    country_id: BSON::ObjectId.from_string(country.id),
                    country_name: row['level_1_name']&.strip,
                    province_id: BSON::ObjectId.from_string(province.id),
                    province_name: row['level_2_name']&.strip,
                    state_id: !(state.nil?) ? BSON::ObjectId.from_string(state.id) : nil,
                    state_name: row['level_3_name']&.strip,
                    city_id: !(city.nil?) ? BSON::ObjectId.from_string(city.id) : nil,
                    city_name: !(city.nil?) ? city.name : nil,
                    type_institution: row[0]&.strip,
                    inep_code: unique_code
                  )
                  school.save!
                  Rails.logger.info(school.errors.messages.inspect)
                else
                  school.update_attributes!(
                    name: row['school_name']&.strip,
                    affiliation_id: BSON::ObjectId.from_string(institution.id),
                    affiliation_name: institution.name,                 
                    country_id: BSON::ObjectId.from_string(country.id),
                    country_name: row['level_1_name']&.strip,
                    province_id: BSON::ObjectId.from_string(province.id),
                    province_name: row['level_2_name']&.strip,
                    state_id: !(state.nil?) ? BSON::ObjectId.from_string(state.id) : nil,
                    state_name: row['level_3_name']&.strip,
                    city_id: !(city.nil?) ? BSON::ObjectId.from_string(city.id) : nil,
                    city_name: !(city.nil?) ? city.name : nil,
                    type_institution: row[0]&.strip,
                    inep_code: unique_code)
                end
              end  
            end
            render json: {status: 'SUCCESS', message:'Schools uploaded', data: {errors: school_error}}, status: :ok
          end 
        elsif user.admin_country?
          header_error = []
          csv_file = params[:file]
          header = CSV.open(csv_file.path, &:readline)
          header.each { |value| value.gsub!("﻿", "") }
          if header != ["type", "affiliation", "school_name", "level_1_name", "level_2_name", "level_3_name", "level_4_name", "unique_code"]
            header_error.push("The CSV structure must have: type,affiliation,school_name,level_1_name,level_2_name,level_3_name,level_4_name,unique_code")
          end
          if !header_error.empty?
            render json: {status: 'ERROR', message:'Invalid CSV structure.', data: {school_name: nil, line: 1, errors: header_error}},status: :unprocessable_entity
          else
            upload_geographical_csv
            upload_institution_csv
            school_error = []
            csv_file = params[:file]
            CSV.foreach(csv_file.path, encoding: "UTF-8", headers: true).with_index(1) do |row, row_number| 
              errors = []
              if row['school_name'].nil?
                errors.push("School name not found.")
              end
              if row['affiliation'].nil?
                errors.push("Instituition not found.")
              end
              if row['level_1_name'].nil?
                errors.push("Geographic structure (country) not found.")
              end
              if row['level_2_name'].nil?
                errors.push("Geographic structure (level 2) not found.")
              end
              if !errors.empty?
                school_error.push({school_name: row['school_name']&.strip, line: row_number, errors: errors})
              else
                country = Country.where(name: row['level_1_name']&.strip).first

                if(user.country_id != country.id)
                  school_error.push({school_name: row['school_name']&.strip, line: row_number, errors: errors})
                end
                
                if !country.nil?
                  province = Province.where(name: row['level_2_name']&.strip, country_id: BSON::ObjectId.from_string(country.id)).first
                end
                if !province.nil?
                  state = State.where(name: row['level_3_name']&.strip, 
                                      country_id: BSON::ObjectId.from_string(country.id),
                                      province_id: BSON::ObjectId.from_string(province.id)).first
                end
                if !state.nil?
                  city = City.where(name: !row['level_4_name'].nil? ? row['level_4_name']&.strip : nil, 
                                    country_id: BSON::ObjectId.from_string(country.id),
                                    province_id: BSON::ObjectId.from_string(province.id),
                                    state_id: BSON::ObjectId.from_string(state.id)).first
                end
                institution = Institution.where(
                  name: row['affiliation']&.strip,
                  country_id: BSON::ObjectId.from_string(country.id)
                ).first

                unique_code = row['unique_code']&.strip
                school = nil
                if (!unique_code.nil?) && (unique_code != "")
                  school = School.where(
                    inep_code: unique_code,
                    affiliation_name: row['affiliation']&.strip,
                    country_id: BSON::ObjectId.from_string(country.id),
                    province_id: BSON::ObjectId.from_string(province.id),
                    state_id: !(state.nil?) ? BSON::ObjectId.from_string(state.id) : nil,
                    city_id: !(city.nil?) ? BSON::ObjectId.from_string(city.id) : nil,).first
                end
                
                if (school.nil?)
                  school = School.where(
                    name: row['school_name']&.strip,
                    affiliation_name: row['affiliation']&.strip,
                    country_id: BSON::ObjectId.from_string(country.id),
                    province_id: BSON::ObjectId.from_string(province.id),
                    state_id: !(state.nil?) ? BSON::ObjectId.from_string(state.id) : nil,
                    city_id: !(city.nil?) ? BSON::ObjectId.from_string(city.id) : nil,).first
                end
                  
                if (school.nil?) # Insert
                  school = School.new(
                    name: row['school_name']&.strip,
                    affiliation_id: BSON::ObjectId.from_string(institution.id),
                    affiliation_name: institution.name,                 
                    country_id: BSON::ObjectId.from_string(country.id),
                    country_name: row['level_1_name']&.strip,
                    province_id: BSON::ObjectId.from_string(province.id),
                    province_name: row['level_2_name']&.strip,
                    state_id: !(state.nil?) ? BSON::ObjectId.from_string(state.id) : nil,
                    state_name: row['level_3_name']&.strip,
                    city_id: !(city.nil?) ? BSON::ObjectId.from_string(city.id) : nil,
                    city_name: !(city.nil?) ? city.name : nil,
                    type_institution: row[0]&.strip,
                    inep_code: unique_code
                  )
                  school.save!
                  Rails.logger.info(school.errors.messages.inspect)
                else
                  school.update_attributes!(
                    name: row['school_name']&.strip,
                    affiliation_id: BSON::ObjectId.from_string(institution.id),
                    affiliation_name: institution.name,                 
                    country_id: BSON::ObjectId.from_string(country.id),
                    country_name: row['level_1_name']&.strip,
                    province_id: BSON::ObjectId.from_string(province.id),
                    province_name: row['level_2_name']&.strip,
                    state_id: !(state.nil?) ? BSON::ObjectId.from_string(state.id) : nil,
                    state_name: row['level_3_name']&.strip,
                    city_id: !(city.nil?) ? BSON::ObjectId.from_string(city.id) : nil,
                    city_name: !(city.nil?) ? city.name : nil,
                    type_institution: row[0]&.strip,
                    inep_code: unique_code)
                end 
              end    
            end
            render json: {status: 'SUCCESS', message:'Schools uploaded', data: {errors: school_error}}, status: :ok
          end 
        end
      end

      def index
        @complete = params[:complete]
        @school_search = SchoolSearch.new(search_params)

        respond_to do |format|
          format.json
        end
      end

      def show
        render json: @school.as_json(:include => [:school_infra])
        @school = nil
      end

      def create
        @school = School.new(school_params)

        if current_user.admin_state?
          @school.state = current_user.state
          @school.type = "Estadual"
        end

        if current_user.admin_city?
          @school.state = current_user.state
          @school.city = current_user.city
          @school.type = "Municipal"
        end

        if @school.save
          render json: @school.as_json
          @school = nil
        else
          render json: @school.errors, status: :internal_server_error
        end
      end

      def destroy
        @school.active = false
        if @school.save
          render json: @school.as_json
          @school = nil
        else
          render json: @school.errors, status: :internal_server_error
        end
      end

      def update
        institution = Instituition.where(:_id => current_user.affiliation_id)
        @school.type = institution.type
        @school.state = current_user.state
        @school.city = current_user.city

        user_has_access = current_user.admin? || current_user.principal?
        if user_has_access && @school.update(school_params)
          render json: @school.as_json
          @school = nil
        elsif user_has_access
          render json: @school.errors, status: :internal_server_error
        else
          render json: { errors: { user: "doesn't has acces" } }
        end
      end

      def regionals
        
        @schools = []
        user = current_user

        if(user.admin_state?)
          @schools = School.where(affiliation_id: BSON::ObjectId.from_string(user['affiliation_id'])).distinct(:regional)
        elsif(user.admin_country?)
          @schools = School.where(country_id: BSON::ObjectId.from_string(user['country_id'])).distinct(:regional)
        end
        
        render json: @schools.as_json
        @schools = nil
      end

      def survey_response
        raList = ResponseAnswer.where(:user_id => current_user.id, :school_id => @school.id)
        responses = Array.new
        raList.each do |resp|
          responses.push(resp)
        end
        @survey_response = @school.survey_response
        @section_1_scores = @survey_response.position_section_scores(1, responses, @school)
        @section_2_scores = @survey_response.position_section_scores(2, responses, @school)
        @section_3_scores = @survey_response.position_section_scores(3, responses, @school)
        @section_4_scores = @survey_response.position_section_scores(4, responses, @school)
        respond_to do |format|
          format.pdf do
            render pdf: 'survey_response',
              layout: 'pdf', orientation: 'Landscape',
              file: "#{Rails.root}/app/views/api/v1/schools/survey_response_#{@school.state.to_s.downcase}.pdf.haml",
              margin:  { top: 0,bottom: 0, left: 0, right: 0 }, show_as_html: params.key?('debug')
          end
        end
      end

      def survey_example
        @survey_response = SurveyResponse.new(vision_level: 1, resource_level: 2, competence_level: 3, infrastructure_level: 4)
        respond_to do |format|
          format.pdf do
            render pdf: 'resposta', layout: 'pdf', orientation: 'Landscape',
              margin:  { top: 0,bottom: 0, left: 0, right: 0 }, show_as_html: params.key?('debug')
          end
        end
      end

      def valid_schools
        valid = true
        begin
          user = current_user
          str = nil
          count = nil
          scArray = nil
          scArray = get_schools_by_profile          
          scArray.update_all({:sample => false})
          user.update_attributes(:school_validate => false)
          count = scArray.length
          arrayList = nil
          number_schools = SchoolsController.calculate_number_schools(count)
          arrayList = scArray.sample(number_schools)
          rankSchools = SchoolsController.sort_schools(scArray)
          idsSample = []
          rankSchools.each_with_index do |rs, index|
            objectId = rs[0].to_s.split(':')[1]
            if (index < number_schools)
              idsSample.push(objectId)
            end
          end

          School.where(id:{"$in" => idsSample}).update_all(:sample => true)
          user.update_attributes(:school_validate => true)
        rescue Exception => e
          valid = false
          Rails.logger.error "Class: SchoolsController, method: valid_schools "
          Rails.logger.error e.backtrace.join("\n")
        end
        respond_to do |format|
  				format.json {
  					if valid == true
  						render :json => {:valid => true }.to_json, :status => 200
  					else
  						render :json => {:valid => false }.to_json, :status => 200
  					end
  				 }
    		end
      end

      def has_answereds
        user = current_user
        has_ans = get_schools_by_profile.where(:answered => true).first ? true : false
        render json: { has_answereds: has_ans }
      end

      def has_samples
        user = current_user
        has_sam = get_schools_by_profile.where(:sample => true).first ? true : false
        render json: { has_samples: has_sam }
      end

      def user_school
        user = current_user
        render json: user.school.as_json
        user = nil
      end

      def user_answered
        user = current_user
        has_ans = SurveyResponse.where(:user => user,:school => user.school).first ? true : false
        render json: { has_answered: has_ans }
      end

      def map_data
        match = { '$match' => {
          :type => { '$in' => ["Estadual", "Municipal"] },
          :vision_level => { '$exists' => true },
          :answered => true } }
        group1 = { '$group' => {
            :_id => {
                :state => "$state_name",
                :state_id => "$state_id",
                :type => "$type",
                :level => { '$min' => ["$vision_level", "$competence_level", "$resource_level", "$infrastructure_level"] } },
            :count => { '$sum' => 1 } } }
        lookup = { '$lookup' => {
            :from => "states",
            :localField => "_id.state_id",
            :foreignField => "_id",
            'as' => "state"} }
        unwind = { '$unwind' => "$state" }
        group2 = { '$group' => {
            :_id => {
                :state => "$_id.state",
                :coordinates => "$state.coordinates",
                :acronym => "$state.acronym",
                :align_mark => "$state.align_mark",
                :type => "$_id.type"},
            :levels => { '$push' => {
                :level => "$_id.level",
                :count => "$count"} } ,
            :count => { '$sum' => "$count" } } }
        group3 = { '$group' => {
            :_id => {
                :state => "$_id.state",
                :coordinates => "$_id.coordinates",
                :align_mark => "$_id.align_mark",
                :acronym => "$_id.acronym"},
            :type => { '$push' => {
                :type => "$_id.type",
                :levels => "$levels",
                :count => "$count"} } ,
            :total => { '$sum' => "$count" } } }
        project = { '$project' => {
            :_id => false,
            :state => "$_id.state",
            :acronym => "$_id.acronym",
            :coordinates => "$_id.coordinates",
            :align_mark => "$_id.align_mark",
            :total => true,
            :type => true } }
        @response = School.collection.aggregate([match, group1, lookup, unwind, group2, group3, project]).to_a
        groupTotal = { '$group' => {
            :_id => {
                :state => "$state_name",
                :state_id => "$state_id",
                :type => "$type" },
            :count => { '$sum' => 1 } } }
        @total = School.collection.aggregate([groupTotal]).to_a

        @total.each do |state|
            @response.each do |result|
              if state[:_id][:state] == result[:state]
                result[:type].each do |type|
                  if state[:_id][:type] == type[:type]
                    type[:total_schools] = state[:count]
                    type[:percent] = type[:count].to_f / type[:total_schools]
                  end
                end
              end
            end
        end

        render json: @response.as_json
        @response = nil
        GC.start(immediate_sweep: true)
      end

      def schools_diagnostic_data
        
        user = current_user

        if(params['year'].present?)
          if(user.admin?)
            if(params['country_id'].present?)
              if(params['affiliation_id'].present?)
                surveySched = SurveySchedule.where(:name => params['year']).where(:affiliation_id => BSON::ObjectId.from_string(params['affiliation_id'])).first
                sid = surveySched['id'].to_s
                schools = School.where(:affiliation_id => BSON::ObjectId.from_string(params['affiliation_id']))
                result = []
                k = []
                schools.each do |s|
                  k = {
                    "school_id" => s['id'].to_s,
                    "school_name" => s['name'],
                    "levels" => {
                      "1" => 0,
                      "2" => 0,
                      "3" => 0,
                      "4" => 0
                    }
                  }
                  if(!s['results'].nil?)
                    if(s['results'].keys.include?(sid))
                      k = {
                        "school_id" => s['id'].to_s,
                        "school_name" => s['name'],
                        "levels" => {
                          "1" => s['results'][sid]['vision_level'],
                          "2" => s['results'][sid]['competence_level'],
                          "3" => s['results'][sid]['resource_level'],
                          "4" => s['results'][sid]['infrastructure_level'],
                        }
                      }
                    end
                  end
                  result.push(k)
                end
              else
                inst = Institution.where(:country_id => BSON::ObjectId.from_string(params['country_id']))
                instIds = []
                inst.pluck(:id).each do |k|
                  instIds.push(k.to_s)
                end

                result = []
                k = []
                
                inst.each do |i|
                  ts = School.where(:country_id => BSON::ObjectId.from_string(params['country_id'])).where(:affiliation_id => BSON::ObjectId.from_string(i['id'])).count
                  k = {
                    "affiliation_name" => i['name'],
                    "total" => 0,
                    "levels" => {
                      "1" => 0,
                      "2" => 0,
                      "3" => 0,
                      "4" => 0
                    },
                    "percent" => 0,
                    "total_schools" => ts
                  }
                  result.push(k)
                end

                surveysSchedules = []
                instIds.each do |i|
                  s = SurveySchedule.where(:name => params['year']).where(:affiliation_id => i)
                  if(!s.empty?)
                    surveysSchedules.push(s)
                  end
                end

                surveysSchedules = surveysSchedules.flatten

                sids = surveysSchedules.pluck(:id)
                surveyIds = []
                sids.each do |sid|
                  surveyIds.push(sid.to_s)
                end

                schoolswithresults = []
                instIds.each do |i|
                  s = School.where.not(:results => nil).where(affiliation_id: i)
                  if(!s.empty?)
                    schoolswithresults.push(s)
                  end
                end

                schoolswithresults = schoolswithresults.flatten

                surveyIds.each do |sid|
                  schoolswithresults.each do |school|
                    if(school['results'].keys.include?(sid))
                      a = result.find {|k,v| k['affiliation_name'] == school['affiliation_name']}
                      m = [school['results'][sid]['vision_level'].to_i, school['results'][sid]['competence_level'].to_i,
                          school['results'][sid]['resource_level'].to_i, school['results'][sid]['infrastructure_level'].to_i].min
                      m = m.to_i
                      a['levels'][m] =  a['levels'][m].to_i + 1
                      a['total'] = a['total'].to_i + 1
                    end
                  end
                end

                result.each do |r|
                  if(r['total_schools'].to_i == 0) 
                    r['percent'] = 0.0
                  else
                    r['percent'] = r['total'].to_i/r['total_schools'].to_f
                  end
                end
              end
            else

              countries = Country.where.not(name: 'Dummy Country For Unaffiliated Users').order(:name => 1)

              countries = countries.pluck(:name).to_a
              result = []
              k = []
              countries.each do |c|
                ts = School.where(:country_name => c).count
                k = {
                  "country_name" => c,
                  "total" => 0,
                  "levels" => {
                    "1" => 0,
                    "2" => 0,
                    "3" => 0,
                    "4" => 0
                  },
                  "percent" => 0,
                  "total_schools" => ts
                }
                result.push(k)
              end

              surveysSchedules = SurveySchedule.where(:name => params['year'])
              sids = surveysSchedules.pluck(:id)
              surveyIds = []
              sids.each do |sid|
                surveyIds.push(sid.to_s)
              end
              
              schoolswithresults = School.where.not(:results => nil).where.not(:country_name => 'Dummy Country For Unaffiliated Users')

              surveyIds.each do |sid|
                schoolswithresults.each do |school|
                  if(school['results'].keys.include?(sid))
                    a = result.find {|k,v| k['country_name'] == school['country_name']}
                    m = [school['results'][sid]['vision_level'].to_i, school['results'][sid]['competence_level'].to_i,
                         school['results'][sid]['resource_level'].to_i, school['results'][sid]['infrastructure_level'].to_i].min
                    m = m.to_i
                    a['levels'][m] =  a['levels'][m].to_i + 1
                    a['total'] = a['total'].to_i + 1
                  end
                end
              end

              result.each do |r|
                if(r['total_schools'].to_i == 0) 
                  r['percent'] = 0.0
                else
                  r['percent'] = r['total'].to_i/r['total_schools'].to_f
                end
              end
            end
          elsif(user.admin_country?)
            if(params['country_id'].present?)
              if(params['country_id'] == user.country_id.to_s)
                if(params['affiliation_id'].present?)
                  surveySched = SurveySchedule.where(:name => params['year']).where(:affiliation_id => BSON::ObjectId.from_string(params['affiliation_id'])).first
                  sid = surveySched['id'].to_s
                  schools = School.where(:affiliation_id => BSON::ObjectId.from_string(params['affiliation_id']))
                  result = []
                  k = []
                  schools.each do |s|
                    k = {
                      "school_id" => s['id'].to_s,
                      "school_name" => s['name'],
                      "levels" => {
                        "1" => 0,
                        "2" => 0,
                        "3" => 0,
                        "4" => 0
                      }
                    }
                    if(!s['results'].nil?)
                      if(s['results'].keys.include?(sid))
                        k = {
                          "school_id" => s['id'].to_s,
                          "school_name" => s['name'],
                          "levels" => {
                            "1" => s['results'][sid]['vision_level'],
                            "2" => s['results'][sid]['competence_level'],
                            "3" => s['results'][sid]['resource_level'],
                            "4" => s['results'][sid]['infrastructure_level'],
                          }
                        }
                      end
                    end
                    result.push(k)
                  end
                else
                  inst = Institution.where(:country_id => BSON::ObjectId.from_string(user['country_id']))
                  instIds = []
                  inst.pluck(:id).each do |k|
                    instIds.push(k.to_s)
                  end
      
                  result = []
                  k = []
                  
                  inst.each do |i|
                    ts = School.where(:country_id => BSON::ObjectId.from_string(params['country_id'])).where(:affiliation_id => BSON::ObjectId.from_string(i['id'])).count
                    k = {
                      "affiliation_name" => i['name'],
                      "total" => 0,
                      "levels" => {
                        "1" => 0,
                        "2" => 0,
                        "3" => 0,
                        "4" => 0
                      },
                      "percent" => 0,
                      "total_schools" => ts
                    }
                    result.push(k)
                  end
      
                  surveysSchedules = []
                  instIds.each do |i|
                    s = SurveySchedule.where(:name => params['year']).where(:affiliation_id => i)
                    if(!s.empty?)
                      surveysSchedules.push(s)
                    end
                  end
      
                  surveysSchedules = surveysSchedules.flatten
      
                  sids = surveysSchedules.pluck(:id)
                  surveyIds = []
                  sids.each do |sid|
                    surveyIds.push(sid.to_s)
                  end
      
                  schoolswithresults = []
                  instIds.each do |i|
                    s = School.where.not(:results => nil).where(affiliation_id: i)
                    if(!s.empty?)
                      schoolswithresults.push(s)
                    end
                  end
      
                  schoolswithresults = schoolswithresults.flatten
      
                  surveyIds.each do |sid|
                    schoolswithresults.each do |school|
                      if(school['results'].keys.include?(sid))
                        a = result.find {|k,v| k['affiliation_name'] == school['affiliation_name']}
                        m = [school['results'][sid]['vision_level'].to_i, school['results'][sid]['competence_level'].to_i,
                             school['results'][sid]['resource_level'].to_i, school['results'][sid]['infrastructure_level'].to_i].min
                        m = m.to_i
                        a['levels'][m] =  a['levels'][m].to_i + 1
                        a['total'] = a['total'].to_i + 1
                      end
                    end
                  end
      
                  result.each do |r|
                    if(r['total_schools'].to_i == 0) 
                      r['percent'] = 0.0
                    else
                      r['percent'] = r['total'].to_i/r['total_schools'].to_f
                    end
                  end
                end
              end
            end
          end     

          @response = result

          render json: @response.as_json
          @response = nil
        else
          render json: {status: 'ERROR', message:'Year is required', data: params},status: '400'
        end

      end

      def export_microdata_get_file
        user = current_user
        job = Job.where(user_id: user.id, id: BSON::ObjectId.from_string(params[:id])).first

        if (!job.nil?)
          if (!job.status)
            render json: {status: 'ERROR', message:'File not done', data: nil},status: :unprocessable_entity
          else
            allowed_partial job.link
            csv_file = File.open(@address)
            csv_content = csv_file.read
            respond_to do |format|
              format.html
              format.csv { send_data csv_content, filename: job.filename }
            end
          end
        else
          render json: {status: 'ERROR', message:'File not found', data: nil},status: :not_found
        end

      end
      
      def allowed_partial address
        address = address[0] == "/" ? address[1..-1] : address
        @address = address
      end

      def export_schools_microdata
        user = current_user
        jobSequential = Job.where(user_id: user.id).count
        jobSequential += 1
        filename = "Schools-#{Time.now.getutc.to_i}.csv"
        allowed_partial "#{Rails.root}/public/uploads/#{filename}"
        job = Job.new(user_id: user.id, type: 'school', seq: jobSequential, status: false, finished_at: nil, filename: filename, link: @address)
        job.save

        job.perform(user)

        render json: job.as_json

      end
      
      def export_teachers_microdata
        
        user = current_user
        jobSequential = Job.where(user_id: user.id).count
        jobSequential += 1
        filename = "Teachers-#{Time.now.getutc.to_i}.csv"
        allowed_partial "#{Rails.root}/public/uploads/#{filename}"
        job = Job.new(user_id: user.id, type: 'teacher', seq: jobSequential, status: false, finished_at: nil, filename: filename, link: @address)
        job.save

        job.perform(user)

        render json: job.as_json

      end

      def self.calculate_number_schools(size_schools)
        total = 1.3*(size_schools*(1.96**2)*(0.5**2))/((size_schools-1)*(0.1**2)+(1.96**2)*(0.5**2))
        return total.round
      end

      def self.sort_schools(schools)
        schoolArray = []
        schools.each do |s|
          ran = rand(0.0...10.0)
          schoolArray.push([ ":" + s.id.to_s, ran])
        end
        schoolArray = schoolArray.sort {|a,b| a[1] <=> b[1]}
        return schoolArray
      end

      def self.retrieveObject(array, ele)
        elem = nil
        array.each do |a|
          if a.id.to_s ==  ele
            elem = a
          end
        end
        return elem
      end

      protected

      def search_params
        school_search_params = {
            query: params[:q],
            sort_field: params[:sort],
            sort_direction: params[:sort_dir],
            page: params[:page],
            limit: params[:limit],
        }

        if params.include? :type
          school_search_params[:type] = params[:type]
        end

        if params.include? :city_id
          school_search_params[:city] = City.find(params[:city_id])
          school_search_params[:state_id] = params[:state_id]
          school_search_params[:province_id] = params[:province_id]
          school_search_params[:country_id] = params[:country_id]
        else

          #monitor state
          if current_user.monitor_state?
            school_search_params[:type] = "Estadual"
            school_search_params[:state] = current_user.state
          end

          #monitor city
          if current_user.monitor_city?
            school_search_params[:type] = "Municipal"
            school_search_params[:state] = current_user.state
            school_search_params[:city] = current_user.city
          end

          #monitor state regional
          if current_user.monitor_state_regional?
            school_search_params[:type] = "Estadual"
            school_search_params[:state] = current_user.state
            school_search_params[:regional] = current_user.regional
          end

          #monitor city regional
          if current_user.monitor_city_regional?
            school_search_params[:type] = "Municipal"
            school_search_params[:state] = current_user.state
            school_search_params[:city] = current_user.city
            school_search_params[:regional] = current_user.regional
          end

          #admin state
          if current_user.admin_state?
            school_search_params[:type] = "Estadual"
            school_search_params[:state] = current_user.state
          end

          #admin city
          if current_user.admin_city?
            school_search_params[:city] = current_user.city
            school_search_params[:state] = current_user.state
            school_search_params[:type] = "Municipal"
          end

          #admin_cieb
          if current_user.profile == "admin"
            school_search_params[:type] = params[:network]
            if params.include? :state
              school_search_params[:state] = State.find(params[:state])
            end
            if params.include? :city
              school_search_params[:city] = City.find(params[:city])
            end
          end

          if params.include? :complete
            school_search_params[:complete] = params[:complete]
          end

        end

        school_search_params
      end

      private

      def set_school
        @school = School.find(params[:id])
      end

      def school_params
        params.require(:school).permit(:access_token, :name, :affiliation_name, :country_name, :province_name, :state_name, :city_name, :affiliation_id, :unique_code, :staff_count, :student_diurnal_count, :student_vespertine_count, :student_nocturnal_count, :student_full_count, {school_classe: [:kindergarten, :elementary_1, :elementary_2, :highschool, :technical, :adult]}, :location_type, :manager, :observations, :country_id, :province_id, :state_id, :city_id, {school_infra: [:comp_teachers, :comp_admins, :comp_students, :printers, :rack, :nobreak, :switch, :firewall, :wifi, :projector, :charger, :maker]})
      end
    end
  end
end