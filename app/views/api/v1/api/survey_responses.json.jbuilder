I18n.locale = (!@lang.nil?) ? @lang : I18n.default_locale

json.response do
    json._id @response.id
    json.competence_level @response.competence_level
    json.guests @response.guests
    json.in_use @response.in_use
    json.infrastructure_level @response.infrastructure_level
    json.invited_teacher @response.invited_teacher
    json.number_of_tries @response.number_of_tries
    json.number_of_tries_left @response.number_of_tries_left
    json.resource_level @response.resource_level
    
    json.results @response.results
 
    json.school_id @school.id
    json.status @response.status

    json.survey do 
        json._id @survey.id
        json.active @survey.active
        json.description @survey.description
        json.feedback @survey.feedback
        json.has_combined @survey.has_combined
        json.is_cyclic @survey.is_cyclic
        json.name @survey.name
        json.recurrence_days @survey.recurrence_days
        json.shuffle_options @survey.shuffle_options
        json.type @survey.type
        json.user_type @survey.user_type
    end
    json.survey_id @survey.id
    json.survey_schedule_id @schedule.id
    json.type @response.type
    json.user @response.user
    json.vision_level @response.vision_level
end
json.answeres @answeres