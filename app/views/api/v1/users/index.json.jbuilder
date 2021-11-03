json.total_count @user_search.total_count
json.total_pages @user_search.pages_count
json.users @user_search.page_answers do |user|
  json._id user.to_param
  json.name user.name
  json.email user.email
  json.type user.type
  json.profile user._profile
  if user.school
    json.school user.school.name
  end
end
