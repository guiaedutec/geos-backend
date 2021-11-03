json.array!(@survey_questions) do |survey_question|
  json.extract! survey_question, :id, :name, :position, :survey_section_id
  json.url survey_question_url(survey_question, format: :json)
end
