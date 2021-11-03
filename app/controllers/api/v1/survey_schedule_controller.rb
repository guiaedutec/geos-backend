module Api
  module V1
    class SurveyScheduleController < ApiController

      def date_survey
        valid = true
        begin
          user = current_user
          survey = params[:id_survey]
          survey_schedule = nil
          survey_schedule_id = params[:id_schedule]
          if !survey_schedule_id.nil?
            survey_schedule = SurveySchedule.find(survey_schedule_id)
          end
          count = nil
          if survey_schedule.nil?
            survey_schedule = SurveySchedule.find_or_initialize_by(affiliation_id: user.affiliation_id, survey_id: survey)
          end

          if params[:is_cyclic]
            if !params[:start_date]
              if params[:end_date]
                ms = Date.parse(params[:end_date]) - survey_schedule.survey_end_date
                survey_schedule.survey_end_date = params[:end_date]
                survey_schedule.missing_days = survey_schedule.missing_days - ms.to_i < 0 ? nil : survey_schedule.missing_days - ms.to_i
                survey_schedule.save

              end
            else
              survey_schedule.survey_start_date = params[:start_date]
              survey_schedule.survey_end_date = params[:end_date]
              survey_schedule.missing_days = 30
              survey_schedule.save
            end
          else
            survey_schedule.recurrence_days = params[:recurrence_days]
            survey_schedule.save
          end
        rescue Exception => e
          valid = false
          Rails.logger.error "Class: SurveyScheduleController, method: date_survey_schools "
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

      def find_date_survey
        user = current_user
        survey_schedule = nil
        survey_schedule = SurveySchedule.where(affiliation_id: user.affiliation_id, :missing_days.nin => ['']).first
        render json: survey_schedule.to_json
      end
    end
  end
end
