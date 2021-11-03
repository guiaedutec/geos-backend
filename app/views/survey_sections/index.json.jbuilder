json.array!(@survey_sections) do |survey_section|
  json.extract! survey_section, :id, :name, :position
  json.url survey_section_url(survey_section, format: :json)
end
