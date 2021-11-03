json.total_count @manager_search.total_count
json.total_pages @manager_search.pages_count
json.managers @manager_search.page_answers do |manager|
  json._id manager.to_param
  json.name manager.name
  json.email manager.email
  if not @manager_search.limit
    json.schools manager.schools do |school|
      json.school_id school.to_param
      json.name school.name
      json.inep_code school.inep_code
      json.state_name school.state_name
      json.city_name school.city_name
    end
  end
end
