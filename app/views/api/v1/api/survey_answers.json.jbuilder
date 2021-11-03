json.answered_sample @school_answer_search.answered_sample_count
json.total_sample @school_answer_search.total_sample_count
json.answered_count @school_answer_search.answered_count
json.total_count @school_answer_search.total_count
json.total_pages @school_answer_search.pages_count
json.answers @school_answer_search.page_answers do |school|
  json.school_id school.to_param
  json.sample school.sample
  json.school_name school.name
  json.school_city school.city.name
  if !@survey_schedule_id.nil? and !school['results'].nil? and !school['results'][@survey_schedule_id].nil?
    json.sample school['results'][@survey_schedule_id]['sample']
    json.answered school['results'][@survey_schedule_id]['answered']
    json.vision_level school['results'][@survey_schedule_id]['vision_level']
    json.competence_level school['results'][@survey_schedule_id]['competence_level']
    json.resource_level school['results'][@survey_schedule_id]['resource_level']
    json.infrastructure_level school['results'][@survey_schedule_id]['infrastructure_level']
  elsif @survey_schedule_id.nil?
    json.sample school['results'].values.last['sample']
    json.answered school['results'].values.last['answered']
    json.vision_level school['results'].values.last['vision_level']
    json.competence_level school['results'].values.last['competence_level']
    json.resource_level school['results'].values.last['resource_level']
    json.infrastructure_level school['results'].values.last['infrastructure_level']
  elsif !@survey_schedule_id.nil? and (school['results'].nil? or school['results'][@survey_schedule_id].nil?)
    json.sample nil
    json.answered nil
    json.vision_level nil
    json.competence_level nil
    json.resource_level nil
    json.infrastructure_level nil
  else
    json.sample school.sample
    json.answered school.answered?
    json.vision_level school.vision_level
    json.competence_level school.competence_level
    json.resource_level school.resource_level
    json.infrastructure_level school.infrastructure_level
  end

  json.manager_name school&.manager&.name.to_s
  json.manager_email school&.manager&.email.to_s
  json.manager_phone school&.manager&.phone.to_s
  json.regional school.regional
  json.observations school.observations
end
