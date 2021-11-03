class ResponseAnswer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :school_id, type: :integer
  field :user_id, type: :integer
  field :survey_response_id, type: :integer

  field :options, type: Array
  field :survey_question_id, type: :integer

  belongs_to :school
  belongs_to :user
  belongs_to :survey_question
  belongs_to  :survey_response

  def score
    scor = 0
    if (survey_question.type == 'radio')
      opt =  Integer(options[0])
      if !survey_question.survey_question_description.nil?
        survey_question.survey_question_description.each_with_index do |sqd, index|
          value = sqd["id"].to_i
          if value === opt
            scor = sqd["weight"]
          end
        end
      end
      scor * survey_question.weight
    elsif (survey_question.type == 'checkbox' || survey_question.type == 'table')
      if !survey_question.survey_question_description.nil?
        survey_question.survey_question_description.each_with_index do |sqd, index|
          value = sqd["id"].to_i
          options.each do |opt|
            if(Integer(opt) == value)
              scor = scor + sqd["weight"]
            end
          end
        end
      end
      scor = scor * survey_question.weight
      if survey_question.not_normalize.nil?
        if scor > survey_question.weight
          scor = survey_question.weight
        end
      end
      scor
    elsif (survey_question.type == 'pc')
      scor = students_per_computer_score(survey_question) * survey_question.weight
      if survey_question.not_normalize.nil?
        if scor > survey_question.weight
          scor = survey_question.weight
        end
      end
      scor
    end
  end

  def self.score_new(survey_question, answer, school)
    scor = 0
    if (survey_question.type == 'radio')
      opt =  Integer(answer.options[0])
      if !survey_question.survey_question_description.nil?
        survey_question.survey_question_description.each_with_index do |sqd, index|
          value = sqd["id"].to_i
          if value === opt
            scor = sqd["weight"]
          end
        end
      end
      scor * survey_question.weight
    elsif (survey_question.type == 'checkbox' || survey_question.type == 'table')
      if !survey_question.survey_question_description.nil?
        survey_question.survey_question_description.each_with_index do |sqd, index|
          value = sqd["id"].to_i
          if defined?(answer.options).nil?
            puts "answer #{answer.inspect}"
          else
            answer.options.each do |opt|
              if(Integer(opt) == value)
                scor = scor + sqd["weight"]
              end
            end
          end
        end
      end
      scor = scor * survey_question.weight
      if survey_question.not_normalize.nil?
        if scor > survey_question.weight
          scor = survey_question.weight
        end
      end
      scor
    elsif (survey_question.type == 'pc')
      weight = survey_question.weight == 1 ? 6 : survey_question.weight
      scor = ResponseAnswer.students_per_computer_score(answer, school.max_shift_students, survey_question) * weight
      if scor > weight
        weight
      else
        if !survey_question.not_normalize.nil?
          scor = scor.round
        end
        scor
      end
    end
  end

  def students_per_computer_score(survey_question)
    max_shift_students = school.max_shift_students
    questions_add_ons = SurveyQuestion.where(:survey_id => survey_question.survey_id, :compound => true, :compound_ref => survey_question.compound_ref).pluck(:_id).uniq
    computers = ResponseAnswer.where(:survey_response_id => survey_response_id, :survey_question_id.in => questions_add_ons, :user_id => user.id).map { |a| a.options[0].to_i }.sum
    case (max_shift_students / (computers.to_f.nonzero? || 1.0)).round
    when 0...2.5 then 1.02
    when 2.5...8.5 then 0.85
    when 8.5...16.5 then 0.68
    when 16.5...30.5 then 0.51
    when 30.5...50 then 0.34
    else 0.17
    end
  end

  def self.students_per_computer_score(answer, max_shift_students, survey_question)
    questions_add_ons = SurveyQuestion.where(:survey_id => survey_question.survey_id, :compound => true, :compound_ref => survey_question.compound_ref).pluck(:_id).uniq
    computers = ResponseAnswer.where(:survey_response_id => answer.survey_response_id, :survey_question_id.in => questions_add_ons, :user_id => answer.user_id).map { |a| a.options[0].to_i }.sum
    case (max_shift_students / (computers.to_f.nonzero? || 1.0)).round
    when 0...2.5 then 1.02
    when 2.5...8.5 then 0.85
    when 8.5...16.5 then 0.68
    when 16.5...30.5 then 0.51
    when 30.5...50 then 0.34
    else 0.17
    end
  end
end
