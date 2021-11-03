class Devolutive

  def initialize(user, school, survey_response)
    @survey_response = survey_response
    @school = school
    @user = user
    raList = ResponseAnswer.where(:user_id => @user.id, :school_id => @school.id)
    responses = Array.new
    raList.each do |resp|
      responses.push(resp)
    end
    @section_1_scores = @survey_response.position_section_scores(1, responses, @school)
    @section_2_scores = @survey_response.position_section_scores(2, responses, @school)
    @section_3_scores = @survey_response.position_section_scores(3, responses, @school)
    @section_4_scores = @survey_response.position_section_scores(4, responses, @school)
  end

end