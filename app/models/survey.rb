class Survey
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,       localize: true
  field :description, localize: true
  field :type, type: String
  field :user_type, type: Array
  field :is_cyclic, type: Boolean
  field :recurrence_days, type: Integer
  field :shuffle_options, type: Boolean
  field :feedback, type: String
  field :has_combined, type: Boolean
  field :active, type: Boolean
  
  field :years, type: Array

  has_many :survey_sections
  has_many :survey_questions
  has_many :survey_responses
  has_many :feedbacks


  def self.default
  end

  def fix_responses
    survey_sections.each do |section|
      questions = section.questions
      section.survey_questions.each(&:destroy)
      section.questions = questions
      section.save
    end

    responses = SurveyResponse.includes(:school).select { |sr| sr.survey == self }
    responses.each { |r| Resque.enqueue(SurveyResponse, r.user_id.to_s) }
  end

  def to_s
    name
  end

private

end
