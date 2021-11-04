module Api
  module V1
    class ApiController < ApplicationController
      require 'csv'

      respond_to :json, :pdf, :xls
      before_action :authenticate_user!, only: [:old_survey_response, :survey_answer, :survey_answers, :survey_answers_details, :survey_response, :change_password, :user_institution]
      before_action :authenticate_admin!, only: [:change_user_password, :country_csv]

      def country_csv
        user = current_user
        if user.admin_state?
          schools = School.where(affiliation_id: user.affiliation_id).order(:country_name => 1, :affiliation_name => 1, :name => 1)
          filename = "Schools-#{Date.today}.csv"
          schools_csv = CSV.generate(headers: true, encoding: Encoding::UTF_8) do |row_csv|
            row_csv << ['type', 'affiliation', 'school_name', 'level_1_name', 'level_2_name', 'level_3_name', 'level_4_name', 'unique_code']
            schools.each do |s|
              affiliation_type = Institution.find_by(id: s.affiliation_id).nil? ? 'Not exists' : Institution.find_by(id: s.affiliation_id).type_institution
              row_csv << [affiliation_type, s.affiliation_name, s.name, s.country_name, s.province_name, s.state_name, s.city_name, s.inep_code]
            end
          end
          respond_to do |format|
            format.html
            format.csv { send_data schools_csv, filename: filename }
          end
        elsif user.admin?
          if params['country_id'].nil?
            schools = School.all.order(:country_name => 1, :affiliation_name => 1, :name => 1)
            filename = "Countries-#{Date.today}.csv"
          else
            schools = School.where(country_id: params['country_id']).order(:country_name => 1, :affiliation_name => 1, :name => 1) 
            filename = "Country-#{Date.today}.csv"
          end
          schools_csv = CSV.generate(headers: true, encoding: Encoding::UTF_8) do |row_csv|
            row_csv << ['type', 'affiliation', 'school_name', 'level_1_name', 'level_2_name', 'level_3_name', 'level_4_name', 'unique_code']
            schools.each do |s|
              affiliation_type = Institution.find_by(id: s.affiliation_id).nil? ? 'Not exists' : Institution.find_by(id: s.affiliation_id).type_institution
              row_csv << [affiliation_type, s.affiliation_name, s.name, s.country_name, s.province_name, s.state_name, s.city_name, s.inep_code]
            end
          end
          respond_to do |format|
            format.html
            format.csv { send_data schools_csv, filename: filename }
          end    
        elsif user.admin_country?
          schools = School.where(country_id: user.country_id).order(:country_name => 1, :affiliation_name => 1, :name => 1) 
          filename = "Countries-#{Date.today}.csv"
          schools_csv = CSV.generate(headers: true, encoding: Encoding::UTF_8) do |row_csv|
            row_csv << ['type', 'affiliation', 'school_name', 'level_1_name', 'level_2_name', 'level_3_name', 'level_4_name', 'unique_code']
            schools.each do |s|
              affiliation_type = Institution.find_by(id: s.affiliation_id).nil? ? 'Not exists' : Institution.find_by(id: s.affiliation_id).type_institution
              row_csv << [affiliation_type, s.affiliation_name, s.name, s.country_name, s.province_name, s.state_name, s.city_name, s.inep_code]
            end
          end
          respond_to do |format|
            format.html
            format.csv { send_data schools_csv, filename: filename }
          end  
        end
      end 
      
      def delete_user_cascade_by_affiliation(affiliation_id)
        @users = User.where(affiliation_id: affiliation_id)
        @users.each do |user|
          ManagerFile.where(user_id: user.id).delete_all
          ResponseAnswer.where(user_id: user.id).delete_all
          SurveyResponse.where(user_id: user.id).delete_all
          UserActivity.where(user_id: user.id).delete_all
        end
        User.where(affiliation_id: affiliation_id).delete_all
      end

      def delete_school_cascade_by_affiliation(affiliation_id)
        @schools = School.where(affiliation_id: affiliation_id)
        @schools.each do |school|
          SchoolInfra.where(school_id: school.id).delete_all
          User.where(school_id: school.id).delete_all
        end
        @schools.delete
      end

      def delete_school_cascade(school_id)
        SchoolInfra.where(school_id: school_id).delete_all
        SurveyResponse.where(school_id: school_id).delete_all
        ResponseAnswer.where(school_id: school_id).delete_all
        User.where(school_id: school_id).delete_all        
        School.find(school_id).delete
      end

      def delete_affiliation_cascade(affiliation_id)
        SurveySchedule.where(affiliation_id: affiliation_id).delete_all
        delete_school_cascade_by_affiliation(affiliation_id)
        User.where(affiliation_id: affiliation_id).delete_all
        User.where(institution_id: affiliation_id).delete_all
        Institution.find(affiliation_id).delete
      end

      def delete_country_cascade(country_id)
        City.where(country_id: country_id).delete_all
        Province.where(country_id: country_id).delete_all
        State.where(country_id: country_id).delete_all
        User.where(country_id: country_id).delete_all
        @schools = School.where(country_id: country_id)
        @schools.each do |school|
          delete_school_cascade(school.id)
        end
        @institutions = Institution.where(country_id: country_id)
        @institutions.each do |institution|
          delete_affiliation_cascade(institution.id)
        end
        Country.find(country_id).delete
      end

      def user_institution
        raise 'error' unless current_user.present?
        user = current_user
        @instititution = Institution.where(:id => user.affiliation_id)
        render json: @instititution.as_json
        user = nil
      end

      def get_schools_by_profile
        user = current_user
        if user.admin_state? 
          schools = School.where(:affiliation_id => user.affiliation_id)
        elsif user.admin? 
          schools = School.all
        elsif user.profile.to_s == "principal" || user.profile.to_s == "teacher"
          schools = School.find_by(:id => user.school_id)
        end

        schools
      end

      def test_get_schools_by_profile
        schools = get_schools_by_profile
        if (!schools.nil?)
            render json: {status: 'SUCCESS', message:'Schools found', data:schools},status: :ok
        else
            render json: {status: 'ERROR', message:'Schools not found', data:schools},status: :not_found
        end 
      end 
      
      # Search for a list of registered schools
      # @param: none parameter
      # @return [JSON]: status, message, data (school id and name, keywords, affiliation id and name, type institution, country id and name, province id and name, state id and name, city id and name, levels 1, 2, 3, and 4 name)
      def get_schools
        schools = School.all.order(:name => 1)
        if (!schools.nil?)
            render json: {status: 'SUCCESS', message:'Schools found', data:schools},status: :ok
        else
            render json: {status: 'ERROR', message:'Schools not found', data:schools},status: :not_found
        end 
      end 

      # Search for a list of registered countries
      # @param: none parameter
      # @return [JSON]: status, message, data (country id and name, geo structure levels 1, 2, 3, and 4 name)
      def countries
        dummyname = 'Dummy Country For Unaffiliated Users'

        if(params['access_token'].present?)
          user = User.find_by(authenticity_token: params['access_token'])
          if(user.admin?)
            countries = Country.all.order(:name => 1)
          else
            countries = Country.where.not(name: dummyname).order(:name => 1)
          end
        else
          countries = Country.where.not(name: dummyname).order(:name => 1)
        end

        if (!countries.empty?)
          render json: {status: 'SUCCESS', message:'Countries found', data:countries},status: :ok
        else
          render json: {status: 'ERROR', message:'Countries not found', data:countries},status: :not_found
        end 
      end  

      # Search for a list of registered institutions
      # @param: none parameter
      # @return [JSON]: status, message, data (institution id and name, type institution, country id and name, province id and name, state id and name, city id and name)
      def institutions
        dummyname = 'Dummy Affiliation For Unaffiliated Users'

        if(params['access_token'].present?)
          user = User.find_by(authenticity_token: params['access_token'])
          if(user.admin_country?)
            institutions = Institution.where(:country_id => user['country_id']).where.not(name: dummyname).order(:name => 1)
          elsif (user.admin?)
            if(params['country_id'].present?)
              institutions = Institution.where(country_id: BSON::ObjectId.from_string(params[:country_id])).order(:name => 1)
            else
              institutions = Institution.all.order(:name => 1)
            end
          else
            institutions = Institution.where.not(name: dummyname).order(:name => 1)
          end
        else
          institutions = Institution.where.not(name: dummyname).order(:name => 1)
        end

        if (!institutions.empty?)
            render json: {status: 'SUCCESS', message:'Institutions found', data:institutions},status: :ok
        else
            render json: {status: 'ERROR', message:'Institutions not found', data:institutions},status: :not_found
        end 
      end 

      # Searches the provinces of a specific country (if the country id is provided), otherwise, it returns a list of all provinces
      # @param: country id, or none parameter
      # @return [JSON]: status, message, data (province id and name, country id and name)
      def provincies
        dummyname = 'Dummy Province For Unaffiliated Users'

        provincies = []
        if params[:country_id]
          provincies = Province.where(:country_id => BSON::ObjectId.from_string(params[:country_id])).where.not(:name => dummyname).order(:name => 1)
        else
          provincies = Province.where.not(:name => dummyname).order(:name => 1)
        end

        if(params['access_token'].present?)
          user = User.find_by(authenticity_token: params['access_token'])
          if(user.admin?)
            if params[:country_id]
              provincies = Province.where(:country_id => BSON::ObjectId.from_string(params[:country_id])).order(:name => 1)
            else
              provincies = Province.all.order(:name => 1)
            end
          end
        end

        if (!provincies.empty?)
            render json: {status: 'SUCCESS', message:'Provincies found', data:provincies},status: :ok
        else
            render json: {status: 'ERROR', message:'Provincies not found', data:provincies},status: :not_found
        end 
      end
      
      # Search the states of a specific country and province (if the country id and province id is provided), otherwise, it returns a list of all states
      # @param: country id and province id, or none parameter
      # @return [JSON]: status, message, data (state id and name, province id and name, country id and name)
      def states
        dummyname = 'Dummy State For Unaffiliated Users'

        states = []
        if params[:country_id] && params[:province_id]
          states = State.where(:country_id => BSON::ObjectId.from_string(params[:country_id]),
                                :province_id => BSON::ObjectId.from_string(params[:province_id])).where.not(:name => dummyname).order(:name => 1)
        elsif params[:country_id]
          states = State.where(:country_id => BSON::ObjectId.from_string(params[:country_id])).where.not(:name => dummyname).order(:name => 1)
        else
          states = State.where.not(:name => dummyname).order(:name => 1)
        end

        if(params['access_token'].present?)
          user = User.find_by(authenticity_token: params['access_token'])
          if(user.admin?)
            if params[:country_id] && params[:province_id]
              states = State.where(:country_id => BSON::ObjectId.from_string(params[:country_id]),
                                    :province_id => BSON::ObjectId.from_string(params[:province_id])).order(:name => 1)
            elsif params[:country_id]
              states = State.where(:country_id => BSON::ObjectId.from_string(params[:country_id])).order(:name => 1)
            else
              states = State.all.order(:name => 1)
            end
          end
        end

        if (!states.empty?)
            render json: {status: 'SUCCESS', message:'States found', data:states},status: :ok
        else
            render json: {status: 'ERROR', message:'States not found', data:states},status: :not_found
        end
      end
    

      # Search the cities of a specific country, province and state (if the country id, province id and state id is provided), otherwise, it returns a list of all cities
      # @param: country id, province id and state id, or none parameter
      # @return [JSON]: status, message, data (city id and name, state id and name, province id and name, country id and name)
      def cities
        dummyname = 'Dummy City For Unaffiliated Users'

        cities = []
        if params[:country_id] && params[:province_id] && params[:state_id]
          cities = City.where(:country_id => BSON::ObjectId.from_string(params[:country_id]),
                              :province_id => BSON::ObjectId.from_string(params[:province_id]),
                              :state_id => BSON::ObjectId.from_string(params[:state_id])
                              ).where.not(:name => dummyname).order(:name => 1)
        elsif params[:country_id]
          cities = City.where(:country_id => BSON::ObjectId.from_string(params[:country_id])).where.not(:name => dummyname).order(:name => 1)                   
        else
          cities = City.where.not(:name => dummyname).order(:name => 1)
        end

        if(params['access_token'].present?)
          user = User.find_by(authenticity_token: params['access_token'])
          if(user.admin?)
            if params[:country_id] && params[:province_id] && params[:state_id]
              cities = City.where(:country_id => BSON::ObjectId.from_string(params[:country_id]),
                                  :province_id => BSON::ObjectId.from_string(params[:province_id]),
                                  :state_id => BSON::ObjectId.from_string(params[:state_id])
                                  ).order(:name => 1)
            elsif params[:country_id]
              cities = City.where(:country_id => BSON::ObjectId.from_string(params[:country_id])).order(:name => 1)                   
            else
              cities = City.all.order(:name => 1)
            end
          end
        end

        if (!cities.empty?)
          render json: {status: 'SUCCESS', message:'Cities found', data:cities},status: :ok
        else
            render json: {status: 'ERROR', message:'Cities not found', data:cities},status: :not_found
        end
      end
      
      # Search the schools of a specific country, province, state and city (if the country id, province id, state id and city id is provided), otherwise, it returns a list of all schools
      # @param: country id, province id, state id and city id, or none parameter
      # @return [JSON]: status, message, data (affiliation id and name, type institution, school id and name, city id and name, state id and name, province id and name, country id and name)
      def schools
        dummyname = 'Dummy School For Unaffiliated Users'

        schools = []

        if params[:country_id] && params[:province_id] && params[:state_id] && params[:city_id]
          schools = School.where({:city_id => BSON::ObjectId.from_string(params[:city_id]),
                                  :state_id => BSON::ObjectId.from_string(params[:state_id]),
                                  :province_id => BSON::ObjectId.from_string(params[:province_id]),
                                  :country_id => BSON::ObjectId.from_string(params[:country_id])
                                }).where.not(:name => dummyname).order(:name => 1)
        elsif params[:affiliation_id]
          schools = School.where(:affiliation_id => BSON::ObjectId.from_string(params[:affiliation_id])).where.not(:name => dummyname).order(:name => 1)                   
        end
          
        if(params['access_token'].present?)
          user = current_user
          if(user.admin?)
            if params[:country_id] && params[:province_id] && params[:state_id] && params[:city_id]
              schools = School.where({:city_id => BSON::ObjectId.from_string(params[:city_id]),
                                      :state_id => BSON::ObjectId.from_string(params[:state_id]),
                                      :province_id => BSON::ObjectId.from_string(params[:province_id]),
                                      :country_id => BSON::ObjectId.from_string(params[:country_id])
                                    }).order(:name => 1)
            elsif (params[:country_id].present?)
              schools = School.where(:country_id => BSON::ObjectId.from_string(params[:country_id])).order(:name => 1)
            elsif params[:affiliation_id]
              schools = School.where(:affiliation_id => BSON::ObjectId.from_string(params[:affiliation_id])).order(:name => 1)                   
            end
          elsif(user.admin_country?)
            if(params[:country_id].present?)
              if(BSON::ObjectId.from_string(user['country_id']) == BSON::ObjectId.from_string(params[:country_id]))
                schools = School.where(:country_id => BSON::ObjectId.from_string(params[:country_id])).order(:name => 1)
              end
            end
          end
        end

        if (!schools.empty?)
          render json: {status: 'SUCCESS', message:'Schools found', data:schools},status: :ok
        else
          render json: {},status: :ok
        end
      end  

      def change_user_password
        @user = User.find_by(:id => params[:id], :affiliation_id => current_user.affiliation_id )
        
        if (@user.nil?)
          render json: {message: 'You cannot change password of users of another affiliation'}, status: :internal_server_error
        end
        
        user_params = {
            password: params[:password]
        }
        if @user.update(user_params)
          render json: @user.as_json
        else
          render json: @user.errors, status: :internal_server_error
        end
      end

      def change_password
        current_user.update password: params[:user][:password]
        render json: {}
      end

      def accepted_term
        if !current_user.term?
          current_user.update_attributes(:term => true)
        end
        respond_to do |format|
          format.json{render :json=>{:term=>current_user.term}.to_json}
        end
      end

      def was_notified
        if !current_user.was_notified?
          current_user.update_attributes(:was_notified => true)
        end
        respond_to do |format|
          format.json{render :json=>{:was_notified=>current_user.was_notified}.to_json}
        end
      end
      
      def survey_answer
        Resque.enqueue(SurveyResponse, current_user.to_param)
        render json: {}
      end

      def survey_answers
        @school_answer_search = SchoolAnswerSearch.new(search_params)
        @survey_schedule_id = params[:survey_schedule_id]

        respond_to do |format|
          format.json
          format.xls do
            file = StringIO.new
            @school_answer_search.to_xls(file)
            send_data file.string.force_encoding('binary'), filename: 'respostas.xls'
          end
        end
      end

      def survey_answers_details
        @school_answer_search_details = SchoolAnswerSearch.new(search_params)
        puts @school_answer_search_details
        respond_to do |format|
          format.json
        end
      end

      def survey_answers_cicle
        aux = search_params
        aux.except(:survey_id)

        @school_answer_search_details = SchoolAnswerSearch.new(aux)
        @survey_schedule_id = params[:survey_schedule_id]

        answered_sample = @school_answer_search_details.answered_sample_count
        sample_count = @school_answer_search_details.total_sample_count
        answered_count = @school_answer_search_details.answered_count
        total_count = @school_answer_search_details.total_count

        response = Hash[
          "answered_count" => answered_count,
          "total_count" => total_count,
          "answered_sample" => answered_sample,
          "total_sample" => sample_count,
        ]
        render json: response.to_json
      end

      def survey_answers_query
        puts search_params
        @school_answer_search = SchoolAnswerSearch.new(search_params)
        @school_answer_search.asc = @school_answer_search.answered_sample_count
        @school_answer_search.tsc = @school_answer_search.total_sample_count
        @school_answer_search.ac = @school_answer_search.answered_count
        @school_answer_search.tc = @school_answer_search.total_count
        @school_answer_search.pc = @school_answer_search.pages_count

        puts @school_answer_search.ac
        puts @school_answer_search.tc
        render json: @school_answer_search.to_json
      end

      def survey_answers_results
        @school_answer_search = SchoolAnswerSearch.new(search_params)
        puts @school_answer_search
        respond_to do |format|
          format.json
        end
      end

      def survey_response
        raise 'error' unless current_user.school.present?
        @school = current_user.school
        @survey_response = current_user.survey_response
        raList = ResponseAnswer.where(:user_id => current_user.id, :school_id => @school.id)
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

      def survey_feedback
        @lang = params[:lang]
        I18n.locale =  (!@lang.nil?) ? @lang :  I18n.default_locale
        raise 'error' unless current_user.present?

        @user = current_user
        survey_id = params[:id_survey]
        @survey = Survey.find_by(:id => survey_id)
        response_id = params[:id_response]
        @survey_response = SurveyResponse.where(:id => response_id).first

        @feedbacks = nil
        if !@user.nil?
          @school = nil
          if @user.profile.to_s == "admin_state"
            state = @user.state.id.to_s
            @school = School.where(:state => state, :type => 'Estadual').first
          elsif @user.profile.to_s == "admin_city"
            city = @user.city.id.to_s
            @school = School.where(:city => city, :type => 'Municipal').first
          elsif @user.profile.to_s == "principal" || @user.profile.to_s == "teacher"
            @school = @survey_response.school
          end
          @feedbacks_local = Feedback.where(:survey => survey_id, :affiliation_id => @school.affiliation_id).order(:page => :asc).to_a
          
          @feedbacks_all = Feedback.where(:survey => survey_id, city: nil, state: nil).order('page ASC').to_a
          @feedbacks = Array.new

          if !@feedbacks_local.nil? && @ffeedbacks_local.present?
            @feedbacks_all.each do |fe|
              local = false
              @feedbacks_local.delete_if do |fe_local|
                if fe.id == fe_local.feedback_id
                  @feedbacks.push(fe_local)
                  local = true
                  true
                end
              end
              unless local
                @feedbacks.push(fe)
              end
            end
            if @feedbacks_local.count > 0
              @feedbacks_local.each do |fe_local|
                @feedbacks.insert(@feedbacks.count - 1, fe_local)
              end
            end
          else
            @feedbacks = @feedbacks_all
          end

          @survey_sections = SurveySection.where(:survey_id => survey_id, :has_result => true).order(:position => :asc)
          if @survey_response
            responses = @survey_response.response_answers
          else
            responses = nil
          end

          if @survey_response && @survey_response.is_combined
            responsesD = SurveyResponse.find_by(:school_id => @survey_response.school_id, :survey_id => @survey_response.survey_id, :survey_schedule_id => @survey_response.survey_schedule_id, :user_id => @survey_response.user_id, :type.nin => ["Combined"]).response_answers
            responsesC1 = SurveyResponse.find(@survey_response.guests[0]["survey_response_id"]).response_answers
            responsesC2 = SurveyResponse.find(@survey_response.guests[1]["survey_response_id"]).response_answers
          end

          @scores = Array.new
          @results = Array.new
          @survey_section_feedbak = Array.new
          @survey_sections.each do |sec|
            if sec.has_result && @survey_response
              if !@survey_response.is_combined
                @scores.push(@survey_response.section_scores(sec, responses, @school))
              else1
                scoreCombined = Array.new
                scoreD = @survey_response.section_scores(sec, responsesD, @school)
                scoreC1 = @survey_response.section_scores(sec, responsesC1, @school)
                scoreC2 = @survey_response.section_scores(sec, responsesC2, @school)

                scoreD.each_with_index do |item, i|
                  scoreCombined.push((scoreD[i] + scoreC1[i] + scoreC2[i]) / 3)
                end

                @scores.push(scoreCombined)
              end

              @survey_response.results.each do |result|
                if result["survey_section_id"] == sec.id
                  @results.push(result)
                end
              end
            end
            if sec.has_feedback
              @survey_section_feedbak.push(sec)
            end
          end

          feedbacks_local = @feedbacks.to_a
          aux_feedback = Array.new
          if @user.profile.to_s == "principal" || @user.profile.to_s == "teacher"
            results = @survey_response.results
            aux_feedbacks = Array.new
            @survey_section_feedbak.each do |sec|
              localIndex = 1
              result_section = results.select { |result| result["survey_section_id"] == sec.id }

              feedbacks_local.delete_if do |feedback|
                flag = false
                if feedback.survey_section_id == sec.id
                  if result_section[0]["value"] == 0
                    result_section[0]["value"] = 1
                  end
                  if localIndex != result_section[0]["value"]
                    flag = true
                  end
                  localIndex += 1
                  if flag
                    true
                  else
                    false
                  end
                end
              end
            end

            if @survey['type'] == 'personal'
              arr_pedagogica = Array.new
              arr_cidadania = Array.new
              arr_desenvolvimento = Array.new
              @survey_response.results.each do |sr|
                if sr['name'].include? 'PEDAGÓGICA'
                  arr_pedagogica.push(sr['value'].to_f)
                end
                if sr['name'].include? 'CIDADANIA DIGITAL'
                  arr_cidadania.push(sr['value'].to_f)
                end
                if sr['name'].include? 'DESENVOLVIMENTO PROFISSIONAL'
                  arr_desenvolvimento.push(sr['value'].to_f)
                end
              end

              @avg_pedagogica = calc_median(arr_pedagogica)
              @avg_cidadania = calc_median(arr_cidadania)
              @avg_desenvolvimento = calc_median(arr_desenvolvimento)
            end

            @feedbacks = feedbacks_local
          end
        end
        @translations = get_translation_by_lang
        lang_parsed = JSON.parse(@translations)
        @data = lang_parsed['data']
        @devolutiveT = @data[0]['DevolutiveReport']
        @descLevel = Array.new
        @descLevel.push(@devolutiveT['levels.0'])
        @descLevel.push(@devolutiveT['levels.1'])
        @descLevel.push(@devolutiveT['levels.2'])
        @descLevel.push(@devolutiveT['levels.3'])
        @descLevel.push(@devolutiveT['levels.4'])

        parameter = Parameter.first
        @colorPrimary = parameter.colorPrimary
        @colorSecondary = parameter.colorSecondary
        
        dummy = "Dummy Affiliation For Unaffiliated Users"

        if(@user.institution.name == dummy)
          @devolutiveT['label.city'] = ""
          @devolutiveT['label.state'] = ""
          @devolutiveT['label.school'] = ""
          @school.city_name = ""
          @school.state_name = ""
          if(@user.profile.to_s == "principal")
            @school.name = @devolutiveT['msgPrincipalNoAff']
          elsif(@user.profile.to_s == "teacher")
            @school.name = @devolutiveT['msgTeacherNoAff']
          else
            @school.name = ""
          end
        end

        @logoHeaderSecondary = wicked_pdf_asset_base64("#{ENV['FRONTEND_URL']}/images/theme/logo-header-secondary-#{@lang}.png")
        render pdf: 'survey_response',
               layout: 'pdf', orientation: 'Landscape',
               file: "api/v1/api/survey_feedback_#{@survey.feedback.downcase}.pdf.haml",
               margin:  { top: 0, bottom: 0, left: 0, right: 0 }, show_as_html: params.key?('debug')
      end

      def wicked_pdf_asset_base64(url)
        asset = URI.open(url, "r:UTF-8") {|f| f.read }
        base64 = Base64.encode64(asset.to_s).gsub(/\s+/, "")
        "data:image/png;base64,#{Rack::Utils.escape(base64)}"
      end

      def calc_median(arr)
        arr.sort!
        length = arr.count
        center = length/2
        length.even? ? ((arr[center] + arr[center - 1])/2).round : arr[center].round
      end

      def school_plans_answers
        @school_answer_search_details = SchoolAnswerSearch.new(search_params)
        puts @school_answer_search_details
        respond_to do |format|
          format.json
          format.xls do
            file = StringIO.new
            @school_answer_search_details.to_xls(file)
            send_data file.string.force_encoding('binary'), filename: 'respostas.xls'
          end
        end
      end

      def school_plans_results
        @institution_priorities = PlanSchoolPriority.where(:institution => current_user.institution_id)
        @total_schools = School.where(search_params).with_plan.count
        respond_to do |format|
          format.json
        end
      end

      def getCombinedResponses(response)
        if(response.invited_teacher)
          responses = SurveyResponse.where(:school_id => response.school_id, :survey_id => response.survey_id, :survey_schedule_id => response.survey_schedule_id, :type => 'Combined')
          responses.each do |r|
            if r.guests.select{|guest| guest[:survey_response_id] == response.id}.size() > 0
              return r
            end
          end
        else
          SurveyResponse.where(:school_id => response.school_id, :survey_id => response.survey_id, :survey_schedule_id => response.survey_schedule_id, :user_id => response.user_id, :type => 'Combined').first
        end
      end

      def export_jobs_microdata
        user = current_user
        jobs = Job.where(user_id: user.id)

        render json: jobs.to_json
      end

      def generate_scores
        I18n.locale =  'pt-BR'
        raise 'error' unless params[:id_response].present?
        @user = current_user
        valid = false
        @response = SurveyResponse.includes(:response_answers, :school).find(params[:id_response])
        @survey = Survey.find(@response.survey_id)
        if @survey.has_combined
          @surveyResponseCombined = getCombinedResponses(@response)
        end
        @responseAnswersDup = @response.response_answers.to_a
        @arrGuests = Array.new
        if !@user.nil? && @response.perform
          if @response.survey.type == "school"
            @response.school.update_attributes({:answered => true})
          end
          @user.update_attributes(
            has_answered_survey: true
          )
          valid = true
          @teachers = params[:teachers]
          if @survey.has_combined && !@teachers.nil? && (@surveyResponseCombined.nil? || !@surveyResponseCombined.present?)
            create_invited_users
          end
        end

        if @survey.has_combined
          if @surveyResponseCombined.nil? || !@surveyResponseCombined.present?
            create_responses_combined
          else
            update_responses_combined
          end
        end

        render json: valid.to_json
      end

      def create_invited_users
        @teachers.each do |teacher|
          isNewUser = false
          @guest = User.where(:email => teacher['email']).first
          invited = {}
          invited["survey_id"] = @response.survey_id
          invited["school_id"] = @response.school_id
          invited_survey = Array.new
          invited_survey.push(invited)

          if !@guest.nil?
            if @guest.invited_survey.nil?
              @guest.invited_survey = invited_survey
            else
              @guest.invited_survey.concat(invited_survey)
            end

            if @guest.cpf.blank?
              @guest.cpf = teacher['cpf'].to_s.strip
            end
            @guest.country_id = @user.country_id
            @guest.province_id = @user.province_id
            @guest.state_id = @user.state_id
            @guest.city_id = @user.city_id
            @guest.school_id = @user.school_id
            @guest.school_type = @user.school_type
            @guest.affiliation_id = @user.affiliation_id
          else
            isNewUser = true
            guest_params = {
                email: teacher['email'].to_s.strip,
                name: teacher['nome'].to_s.strip,
                cpf: teacher['cpf'].to_s.strip,
                password: ([*('A'..'Z'),*('0'..'9')]-%w(0 1 I O)).sample(8).join,
                profile: 'teacher',
                invited_survey: invited_survey,
                school_id: @user.school_id,
                school_type: @user.school_type,
                institution_name: @user.institution_name,
                country_id: @user.country_id,
                province_id: @user.province_id,
                state_id: @user.state_id,
                city_id: @user.city_id,
                affiliation_id: @user.affiliation_id
            }
            @guest = User.new(guest_params)
          end

          if @guest.save
            @guestResponse = SurveyResponse.new(user: @guest, school_id: @response.school_id, survey_id: @response.survey_id, survey_schedule_id: @response.survey_schedule_id, invited_teacher: true)
            @guestResponse.init_response
            guest_status = {
                user_id: @guest._id,
                survey_response_id: @guestResponse._id,
                status: 'Enviado'
            }
            @arrGuests.push(guest_status)
            @surveyQuestion = SurveyQuestion.where(:survey_id => @response.survey_id, :only_principal => true)
            questions_ids = @surveyQuestion.pluck(:_id).uniq
            @responseAnswersDup.each do |ra|
              if questions_ids.include?(ra.survey_question_id)
                ra_params = {
                    school_id: ra.school_id,
                    user_id: @guest._id,
                    survey_response_id: @guestResponse._id,
                    options: ra.options,
                    survey_question_id: ra.survey_question_id
                }
                @ra = ResponseAnswer.new(ra_params)
                @ra.save
              end
            end

            begin
              UserMailer.send_invite(@guest, @user, isNewUser).deliver
            rescue
              puts 'send mail errors'
            end
          else
            puts @guest.errors
          end
        end
      end

      def create_responses_combined
        @responseCombined = @response.dup
        @responseCombined.type = 'Combined'
        @responseCombined.remove_attribute(:submitted_at)
        @responseCombined.guests = @arrGuests
        @responseCombined.save

      end

      def update_responses_combined
        sr_ids = Array.new
        @surveyResponseCombined.guests.each{|g| sr_ids.push(g[:survey_response_id])}
        arrSRCombined = SurveyResponse.includes(:response_answers, :school).any_of({:_id.in => sr_ids, :status => "Complete"}, {:user_id => @surveyResponseCombined.user_id, :survey_schedule_id => @surveyResponseCombined.survey_schedule_id, :status => "Complete", :type.nin => ["Combined"] })
        @surveyResponseCombined.guests.each do |g|
          if arrSRCombined.any?{|ra| ra._id == g[:survey_response_id]}
            g[:status] = "Respondido"
          end
        end
        @surveyResponseCombined.save
        @surveyResponseCombined.combine_responses(arrSRCombined)
      end

      def resend_invite
        status = 200
        valid = false
        user = params[:user]
        manager = params[:manager]

        currentUser = User.find(params[:id])
        currentManager = User.find(manager['id'])

        if !user['newEmail'].nil?
          emailInUse = User.where(:email => user['newEmail']).first
          if emailInUse.nil?
            currentUser.email = user['newEmail']
            currentUser.save
            status = 200
            valid = true
          end
        else
          status = 200
          valid = true
        end

        if valid
          begin
            UserMailer.send_invite(currentUser, currentManager, false).deliver
          rescue
            status = 202
            valid = false
            puts 'send mail errors'
          end
        end

        render json: {:valid => valid}.to_json, :status => status
      end

      def regions
        @regions = Region.all.order(:name => 1)
        render json: @regions.as_json
      end

      def spreadsheets
        if params[:school_id]
          @spreadsheets = SpreadSheet.where({:colVEscola => params[:school_id]})
        else
          @spreadsheets = SpreadSheet.all
        end
        render json: @spreadsheets.as_json
      end

      protected
      def search_params
        
        basic_search_params = {
            query: params[:q],
            sort_field: params[:sort],
            sort_direction: params[:sort_dir],
            page: params[:page],
            filters: params[:filters]
        }

        if current_user.super_admin? || current_user.admin_state? 
          basic_search_params[:affiliation_id] = current_user.affiliation_id
        end

        #super admin
        if current_user.super_admin?
          if params[:city_id]
            basic_search_params[:city] = City.find(params[:city_id])
          end
          if params[:state_id]
            basic_search_params[:state] = State.find(params[:state_id])
          end
        end

        #regional
        if params[:regional]
          basic_search_params[:regional] = params[:regional]
        end

        if params[:survey_schedule_id]
          basic_search_params[:survey_schedule_id] = params[:survey_schedule_id]
        end

        if params[:rf]
          basic_search_params[:rf] = params[:rf]
        end

        basic_search_params
      end

      protected
      def get_translation_by_lang
        translationController = TranslationsController.new
        translationController.request = request
        translationController.response = response
        translationController.get_translation_by_lang
      end 
    end
  end
end