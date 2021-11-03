I18n.locale =  (!@lang.nil?) ? @lang :  I18n.default_locale

json.surveys @list_surveys do |survey|
  json.id survey.to_param
  json.type survey.type
  json.is_cyclic survey.is_cyclic
  
  if current_user.admin_country? then
    json.survey_name survey.name
    json.survey_description survey.description
    json.years survey.years
  
  elsif !current_user.super_admin? then
    json.schedule survey[:schedules] do |schedule|
      json.id schedule.id
      if !schedule.name.nil?
        json.name schedule.name
      end
      json.survey_id schedule.survey_id
      json.survey_name survey.name
      json.survey_description survey.description
      if survey.is_cyclic
        json.is_cyclic true
        json.missing_days schedule.missing_days
        json.survey_end_date schedule.survey_end_date
        json.survey_start_date schedule.survey_start_date
      elsif
      json.recurrence_days schedule.recurrence_days
        json.is_cyclic false
      end
      json.answers @user_answers do |answer|
        if (answer.survey_id == schedule.survey_id && answer.survey_schedule_id == schedule.id)
          json.id answer.id
          json.in_use answer.in_use
          json.status answer.status
          json.submitted_at answer.submitted_at
          json.school_id answer.school_id
          json.school_type answer.school.type
          json.results answer.results
          json.user_id answer.user.id
          json.user_name answer.user.name

          if !answer.guests.nil? && answer.guests.present?
            json.guests answer.guests
          end
          if !answer.type.nil?
            json.type answer.type
          end
          if answer.vision_level == -100
            json.old_response true
          end
        end
      end
    end
  else
    json.survey_name survey.name
    json.survey_description survey.description
    json.years survey.years
  end 
end