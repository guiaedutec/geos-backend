json.total_sample @school_search.total_sample_count
json.total_count @school_search.total_count
json.total_pages @school_search.pages_count
json.schools @school_search.page_answers do |school|
  json.school_id school.to_param
  json.inep school.inep_code
  json.school_name school.name
  json.school_city school.city.name
  json.school_state school.state.name
  #json.manager_name school&.manager&.name.to_s
  #json.manager_email school&.manager&.email.to_s
  #json.manager_phone school&.manager&.phone.to_s
  #json.manager_id school&.manager&.to_param
  json.regional school.regional
  json.observations school.observations
  if @complete
    json.sample school.sample
    json.answered school.answered?
    json.vision_level school.vision_level
    json.competence_level school.competence_level
    json.resource_level school.resource_level
    json.infrastructure_level school.infrastructure_level
    json.kindergarten school.kindergarten
    json.elementary_1 school.elementary_1
    json.elementary_2 school.elementary_2
    json.highschool school.highschool
    json.technical school.technical
    json.adult school.adult
    if not school&.school_infra.nil?
      json.comp_admins school&.school_infra&.comp_admins.to_s
      json.comp_teachers school&.school_infra&.comp_teachers.to_s
      json.comp_students school&.school_infra&.comp_students.to_s
      json.printers school&.school_infra&.printers.to_s
      json.rack school&.school_infra&.rack.to_s
      json.nobreak school&.school_infra&.nobreak.to_s
      json.switch school&.school_infra&.switch.to_s
      json.firewall school&.school_infra&.firewall.to_s
      json.wifi school&.school_infra&.wifi.to_s
      json.projector school&.school_infra&.projector.to_s
      json.charger school&.school_infra&.charger.to_s
      json.maker school&.school_infra&.maker.to_s
    else
      json.comp_admins nil
      json.comp_teachers nil
      json.comp_students nil
      json.printers nil
      json.rack nil
      json.nobreak nil
      json.switch nil
      json.firewall nil
      json.wifi nil
      json.projector nil
      json.charger nil
      json.maker nil
    end
  end
end
