I18n.locale =  (!@lang.nil?) ? @lang :  I18n.default_locale

json.result @sections do |section|
  json._id section.id
  # Fields requiring translation - begin
  json.name section.name
  json.description section.description
  # Fields requiring translation - end
  
  json.pageTitleCssClass section.pageTitleCssClass
  json.position section.position
  json.survey_id section.survey_id
  json.has_feedback section.has_feedback
  json.only_feedback section.only_feedback
  json.has_result section.has_result
  json.has_question section.has_question
  json.divisor section.divisor
  json.user_type section.user_type
  json.survey_question @questions do |question|
     
    if section.id == question.survey_section_id
      json._id question.id
      json.name question.name
      json.question_order question.question_order
      # Fields requiring translation - begin        
      json.type question.type
      json.survey_section_id question.survey_section_id
      json.survey_id question.survey_id
      json.survey_question_description question.survey_question_description
      # Fields requiring translation - end
      
      json.page question.page
      json.obs question.obs
      json.weight question.weight
      json.state question.state
      json.city question.city
      if !question.only_principal.nil?
        json.only_principal question.only_principal
      end
      if !question.compound.nil?
        json.compound question.compound
        json.compound_ref question.compound_ref
        if !question.compound_first.nil?
          json.compound_first question.compound_first
        end
      end
      if !question.has_child.nil?
        json.has_child question.has_child
      end
      json.type_role question.type_role
      json.updated_at question.updated_at
    end
  end
end