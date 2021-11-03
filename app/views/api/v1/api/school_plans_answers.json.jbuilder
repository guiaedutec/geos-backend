json.planned_count @school_answer_search_details.planned_count
json.total_count @school_answer_search_details.total_count
json.total_pages @school_answer_search_details.pages_count
json.answers @school_answer_search_details.page_answers do |school|
  json.plan school.plan?
  json.school_id school.to_param
  json.sample school.sample
  json.answered school.answered?
  json.inep school.inep_code
  json.school_name school.name
  json.school_city school.city.name
  json.regional school.regional
  json.vision school.vision_level
  json.competence school.competence_level
  json.resource school.resource_level
  json.infrastructure school.infrastructure_level
  json.manager_name school&.manager&.name.to_s
  json.manager_email school&.manager&.email.to_s
  json.manager_phone school&.manager&.phone.to_s
  json.observations school.observations
end