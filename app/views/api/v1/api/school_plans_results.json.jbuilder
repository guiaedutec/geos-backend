json.total_schools @total_schools
json.priorities @institution_priorities do |priority|
  json.dimension priority.dimension
  json.css_class priority.css_class
  json.no_dimension_order priority.no_dimension_order
  json.no_order priority.no_order
  json.name priority.name
  json.description priority.description
  json.objective priority.objective
  json.institution priority.institution
  json.actions priority.actions
  json.school_count priority.school_count
end