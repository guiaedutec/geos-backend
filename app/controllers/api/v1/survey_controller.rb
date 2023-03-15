module Api
  module V1
    class SurveyController < ApiController

      # before_action :set_school, only: [:survey_response, :update, :show, :destroy]
      before_action :authenticate_user!, except: [:surveys_list]

      def surveys_list
        @lang = params[:lang]
        user = current_user
        flag_schedule_created = false
        #GEOS
        school_id = user.school_id
        @school = School.find_by(:id => school_id)
        @affiliation = Institution.find_by(:id => user.affiliation_id)
        invited_survey = []
        if user.invited_survey?
          user.invited_survey.each do |invited|
            invited_survey.push(invited["survey_id"])
          end
        end
        @surveys = Survey.any_of({:user_type => user.profile}, {:id.in => invited_survey}).order_by([[:_id, :asc]])
        @list_surveys = Array.new
        @survey_schedule = find_date_survey()

        if(user.admin_country?)
          @survey_schedule = SurveySchedule.all
        end

        @survey_types = @surveys.pluck(:type).uniq
        survey_ids = @surveys.pluck(:_id).uniq
        survey_ids.concat(invited_survey)

        if !user.super_admin?
          if user.principal?
            @school = School.where(:_id => user.school_id).first
            #GEOS
            @user_answers = SurveyResponse.where(:school => user.school_id, :survey.in => survey_ids).inverse_subimitted_order.to_a
            @user_answers.delete_if { |response| response.survey.type == 'personal' && user._id != response.user_id }
            @user_answers.delete_if { |response| response.survey.type == 'personal' }
            @personal_answers = SurveyResponse.where(:user => user, :survey.in => survey_ids).inverse_subimitted_order.to_a
            @personal_answers.delete_if { |response| response.survey.type == 'school' }
            @user_answers.concat(@personal_answers)

            responses = @user_answers.select {|item| item.type == "Combined"}
            if !responses.nil?
              responses.each do |response|
                if !response.guests.nil?
                  response.guests.each do |guest|
                    @user_answers.delete_if do |item|
                      if !item.user.nil? && item.user.id == guest[:user_id]
                        guest[:user_name] = item.user.name
                        true
                      end
                    end
                  end
                end
              end
            end
          elsif user.teacher?
            @user_answers = SurveyResponse.where(:user => user, :survey.in => survey_ids).inverse_subimitted_order.to_a
          end

          @survey_types.each do |type|
            @actual_survey = get_actual_survey(@surveys.to_a, type)
            temp_schedules = Array.new
            has_schedule = false
            now = Time.zone.now
            @surveys.each do |survey|
              if survey.type == type
                @survey_schedule.each do |schedule|     
                  if schedule.survey_id == survey.id && schedule.affiliation_id == user.affiliation_id
                    temp_schedules.push(schedule)
                    if !schedule.survey_end_date.nil? and now < schedule.survey_end_date
                      has_schedule = true
                    elsif schedule.survey_end_date.nil?
                      has_schedule = true
                    end
                  end
                end
                flag_sample = false
                if !has_schedule && survey.active
                  survey_params = Hash.new
                  survey_params[:survey_id] = survey.id
                  survey_params['name'] = now.year.to_s

                  #GEOS
                  if (user.admin_state?)
                    survey_params[:type] = @affiliation.type
                    survey_params[:state_id] = @affiliation.state_id
                  else
                    survey_params[:type] = @school.type
                    survey_params[:state_id] = @school.state_id
                  end if                  

                  survey_params[:affiliation_id] = user.affiliation_id

                  if !survey.is_cyclic
                    survey_params[:recurrence_days] = survey.recurrence_days
                  else
                    survey_params[:survey_start_date] = now
                    survey_params[:survey_end_date] = Time.new now.year, 12, 31, 23, 59, 59
                    survey_params[:missing_days] = 0
                    flag_schedule_created = true
                    flag_sample = true
                  end
                  temp_schedule = SurveySchedule.new(survey_params)

                  temp_schedule.save
                  Rails.logger.info(temp_schedule.errors.messages.inspect)
                  temp_schedules.push(temp_schedule)

                  temp_schedule.set_rdn_sample current_user
                end
                # nao faz diferença usar o schedule['survey_end_date'] pois todos os schedules sao anuais
                temp_schedules.sort_by! { |schedule| schedule['name'] }.reverse!
                @actual_survey[:schedules] = temp_schedules
              end
            end
            @list_surveys.push(@actual_survey)
          end
        else
          @list_surveys = @surveys
          # @list_surveys = @surveys.uniq { |s| s.type }
        end

        if (user.admin?)

          @list_surveys.each do |survey|
            survey[:years] = Array.new 
            if(survey.type == 'school')
              survey[:years] = SurveySchedule.where(:survey_id => survey.id).distinct(:name).sort.reverse!
            end
          end

          if (params['country_id'].present?)
            if(params['affiliation_id'].present?)
              @list_surveys.each do |survey|
                survey[:years] = Array.new 
                if(survey.type == 'school')
                  samecountry = Institution.where(:country_id => BSON::ObjectId.from_string(params['country_id'])).where(:id=>BSON::ObjectId.from_string(params['affiliation_id'])).first
                  if(!samecountry.nil?)
                    survey[:years] = SurveySchedule.where(:survey_id => survey.id).where(:affiliation_id => BSON::ObjectId.from_string(params['affiliation_id'])).distinct(:name).sort.reverse!
                  end
                end
              end
            else
              @list_surveys.each do |survey|
                survey[:years] = Array.new 
                if(survey.type == 'school')
                  y = Array.new
                  # Get the aff_id to search the Surveys
                  Institution.where(:country_id => BSON::ObjectId.from_string(params['country_id'])).each do |aff|
                    a = SurveySchedule.where(:survey_id => survey.id).where(affiliation_id: aff['id']).distinct(:name)
                    if(!a.empty?)
                      y.push(a)
                    end
                  end          
                  y = y.flatten.uniq.sort.reverse!
                  survey[:years] = y
                end
              end
            end
          end
          
        elsif (user.admin_country?)
          if(params['country_id'].present?)
            if(BSON::ObjectId.from_string(params['country_id']) == user.country_id)
              if(params['affiliation_id'].present?)
                @list_surveys.each do |survey|
                  survey[:years] = Array.new 
                  if(survey.type == 'school')
                    samecountry = Institution.where(:country_id => BSON::ObjectId.from_string(params['country_id'])).where(:id=>BSON::ObjectId.from_string(params['affiliation_id'])).first
                    if(!samecountry.nil?)
                      survey[:years] = SurveySchedule.where(:survey_id => survey.id).where(:affiliation_id => BSON::ObjectId.from_string(params['affiliation_id'])).distinct(:name).sort.reverse!
                    else
                      survey[:years] = Array.new
                    end
                  end
                end
              else
                @list_surveys.each do |survey|
                  survey[:years] = Array.new 
                  if(survey.type == 'school')
                    y = Array.new
                    # Get the aff_id to search the Surveys
                    Institution.where(:country_id => BSON::ObjectId.from_string(params['country_id'])).each do |aff|
                      a = SurveySchedule.where(:survey_id => survey.id).where(affiliation_id: aff['id']).distinct(:name)
                      if(!a.empty?)
                        y.push(a)
                      end
                    end
                    y = y.flatten.uniq.sort.reverse!
                    survey[:years] = y
                  end
                end
              end
            else
              @list_surveys[0][:years] = Array.new
              @list_surveys[1][:years] = Array.new
            end
          end
        end

        respond_to do |format|
          format.json
        end
      end

      def update_survey
        user = current_user
        if user.admin?
          @survey = Survey.find(params[:id])

          #Adjust locale to save
          I18n.locale =  (!params[:lang].nil?) ? params[:lang] :  I18n.default_locale
          params.permit(:id, :lang, :survey_name, :survey_description)
          if @survey.update_attributes(
            name: params[:survey_name],
            description: params[:survey_description],
            )
            render json: @survey.to_json
          else
            render json: {status: 'ERROR', message:'Can not perform this action', data: nil},status: :unprocessable_entity
          end
        else
          render json: {status: 'ERROR', message:'Only the admin can perform this action', data: nil},status: :unauthorized
        end
      end

      def get_actual_survey(surveys, type)
        surveys.find{ |survey| survey.type == type && survey.active == true }
      end


      def find_date_survey
        user = current_user
        type = nil
        survey_schedule = nil

        if user.super_admin? || user.admin_state? || user.monitor_state? || user.monitor_state_regional?
          #Get type of all schools of user.affiliation_id
          typesOfSchools = School.where(affiliation_id: user.affiliation_id).pluck(:type_institution).uniq
        elsif user.principal? || user.teacher?
          typesOfSchools = [ user.school.type ]
        end
        # GEOS
        SurveySchedule.includes(:survey).where(:type => {"$in" => typesOfSchools}, :affiliation_id => user.affiliation_id, :missing_days.nin => ['']).invese_created_order
      end


    end
  end

  def build_options(options_response)
    arr = []
    if options_response.instance_of? String
      hash = {}
      arr.push(hash[options_response] = options_response)
    else
      options_response.each do |e|
        hash = {}
        hash[e] = e
        arr.push(hash)
      end
    end
  end

end