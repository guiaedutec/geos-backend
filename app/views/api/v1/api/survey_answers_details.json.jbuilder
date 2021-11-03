json.answered_sample @school_answer_search_details.answered_sample_count
json.total_sample @school_answer_search_details.total_sample_count
json.answered_count @school_answer_search_details.answered_count
json.total_count @school_answer_search_details.total_count
json.total_pages @school_answer_search_details.pages_details_count
json.answers_details @school_answer_search_details.page_details do |school|
    json.school_id school.to_param
    json.sample school.sample
    json.answered school.answered?
    json.inep school.inep_code
    json.school_name school.name
    json.regional school.regional
    json.location_type school.location_type
    json.vision_level school.vision_level
    json.competence_level school.competence_level
    json.resource_level school.resource_level
    json.infrastructure_level school.infrastructure_level
    json.student_diurnal_count school.student_diurnal_count
    json.student_vespertine_count school.student_vespertine_count
    json.student_nocturnal_count school.student_nocturnal_count
    json.student_full_count school.student_full_count
    json.survey_responses school.responses do |responses|
      json.id responses.to_param
      json.in_use responses.in_use
      json.status responses.status
      json.results responses.results
      json.survey_id responses.survey_id
      json.survey_schedule_id responses.survey_schedule_id
      json.user_id responses.user_id
      json.response_answers responses.response_answers
      # created_at: "2018-11-21T15:36:48.142-02:00"
      # submitted_at: "2018-11-23T11:47:18.819-02:00"
      # updated_at: "2018-11-27T14:29:32.456-02:00"
    end
end
