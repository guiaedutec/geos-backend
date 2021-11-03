class SurveySection
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, localize: true
  field :pageTitleCssClass, type: String
  field :position, type: Integer
  field :description, localize: true
  field :has_feedback,  type:Boolean
  field :only_feedback,  type:Boolean
  field :has_result,  type:Boolean
  field :has_question,  type:Boolean
  field :ceil_result, type:String
  field :divisor, type:Float
  field :user_type, type:Array

  belongs_to :survey

  has_many :survey_question, dependent: :destroy
  has_many :feedback
  has_many :thematics

  scope :ordered, -> { order(:position.asc) }

  def sort_survey_question
    ta = survey_questions.sort {|a, b| a[:name] <=> b[:name]}
    return ta
  end

  def sort_resultable_question
    ta = survey_question.select { |result| result["weight"] >= 0 }
    ta = ta.sort {|a, b| a[:name] <=> b[:name]}
    return ta
  end

protected
  def add_stored_questions
    return unless @questions.present?
  end
end
