class SurveyResponse
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Memoist

  MAX_NUMBER_OF_RETRIES = 5
  RESET_NUMBER_OF_RETRIES = 1
  RETRY_PERIOD = 5.minutes

  field :vision_level, type: :integer
  field :competence_level, type: :integer
  field :resource_level, type: :integer
  field :infrastructure_level, type: :integer
  field :status, type: String
  field :submitted_at, type: DateTime
  field :number_of_tries_left, type: Integer, default: MAX_NUMBER_OF_RETRIES
  field :number_of_tries, type: Integer, default: 0
  field :in_use, type: Mongoid::Boolean, default: false
  field :results, type: Array
  field :guests, type: Array
  field :type, type: String
  field :survey, type: Object
  field :user, type: Object
  field :invited_teacher, type: Boolean

  has_many :response_answers, dependent: :destroy
  belongs_to :school
  belongs_to :user
  belongs_to :survey
  belongs_to :survey_schedule

  # update validates
  # validates :school_id, presence: true, uniqueness: { scope: :user_id }

  after_save :update_school_levels
  # delegate :survey, to: :school

  default_scope -> { order_by(:submitted_at.asc) }
  scope :inverse_subimitted_order, -> { order_by(:submitted_at.desc) }
  scope :updated_order, -> { order(:updated_at.asc) }
  scope :complete, -> { where(status: 'Complete') }
  scope :deleted, -> { where(status: 'Deleted') }
  scope :incomplete, -> { where(status: 'Partial') }
  scope :issue, -> { where(status: 'Complete').or([{ vision_level: 0 }, { competence_level: 0 }, { resource_level: 0 }, { infrastructure_level: 0 }]) }
  scope :inuse, -> { where(in_use: true) }

  @queue = :survey_responses
  def perform
    return unless self.response_answers.present?
    complete_response
    complete? && localSendEmail(user)
  end

  def localSendEmail(user)
    if Rails.env.production? || Rails.env.staging?
      UserMailer.send_response(user, self).deliver
    else
      true
    end
  end

  def lst_response_answers(user_id)
    results = Array.new
    sections = SurveySection.where( :position.in => [1,2,3,4])
    sections.map do |section|
      section.sort_survey_question.map do |q|
        responses = ResponseAnswer.where(:user_id => user.id, :survey_question_id => q.id)
        if !responses.nil?
          responses.each do |r|
            results.push(r)
          end
        end
      end
    end
    return results
  end

  def destroy
    update_attribute(:deleted_at, Time.current)
    update_attribute(:active, false)
  end

  def fetch_responses
    return unless user.present? && id.present?
    ResponseAnswer.where(:user_id => user.id, :survey_response_id => id)
  end

  def complete?
    status == 'Complete' && !self.class.issue.include?(self)
  end

  def init_response
    return unless user.present? && survey.present?
    self.school  = school
    self.status  = "Started"
    self.in_use  = false
    self.save
  end

  def complete_response
    self.status       = "Complete"
    self.submitted_at = Time.now

    @survey_sections = SurveySection.where(:survey_id => survey_id, :has_result => true)
    self.results = Array.new
    @survey_sections.each do |section, index|
      result = {}
      result["survey_section_id"] = section.id
      result["name"] = section.name
      result["value"] = score(section, self.response_answers, self.school)
      self.results.push(result)
    end

    self.save
  end

  def score(section, responses, school)
    scores = section_scores(section, responses, school)
    return 0 unless scores.present?
    # puts "score page:" + section.position.to_s + " sum:" + scores.sum.to_s + " size:" + scores.size.to_f.to_s +  " result:" + (scores.sum / scores.size.to_f).round.to_s
    ceil_calculate(section, scores)
  end

  def section_scores(section, responses, school)
    return [] unless !section.nil?
    answer = Object.new
    section.sort_resultable_question.map do |q|
      responses.delete_if do |response|
        if(response.survey_question_id == q.id)
          answer = response
          true
        end
      end
      answer ? ResponseAnswer.score_new(q, answer, school) : 0
    end
  end

  def combine_responses(arrSRCombined)
    if arrSRCombined.length >= 3
      self.status       = "Complete"
      self.submitted_at = Time.now
    end

    @survey_sections = SurveySection.where(:survey_id => survey_id, :has_result => true)
    self.results = Array.new
    @survey_sections.each do |section, index|
      result = {}
      result["survey_section_id"] = section.id
      result["name"] = section.name

      scoresCombined = Array.new
      arrSRCombined.each do |ra|
        scores = section_scores(section, ra.response_answers, self.school)
        scoresCombined.push(scores)
      end

      avgScoresCombined = Array.new
      scoresCombined.first.length.times do |i|
        avg = 0
        scoresCombined.length.times do |j|
          avg += scoresCombined[j][i]
          if scoresCombined.length == j + 1
            avg = avg / scoresCombined.length
          end
        end
        avgScoresCombined.push(avg)
      end
      result["value"] = ceil_calculate(section, avgScoresCombined)

      self.results.push(result)
    end

    self.save
  end

  def ceil_calculate(section, scores)
    #puts "score page:" + section.position.to_s + " sum:" + scores.sum.to_s + " size:" + scores.size.to_f.to_s +  " result:" + (scores.sum / scores.size.to_f).round.to_s
    case section.ceil_result
    when 'ceil' then (scores.sum / section.divisor).ceil
    when 'not_ceil' then (scores.sum / section.divisor)
    when 'down' then (scores.sum / section.divisor).round(half: :down)
    else (scores.sum / section.divisor).ceil
    end
  end





  def worst_section_score_name
    scores = []
    results.each do |result|
      scores.push(result["value"])
    end
    min_value = scores.min
    # Translations of dimensions
    bodySection = Array.new
    bodySection = Feedback.where(:survey => survey_id, :page => 7).first
    text = ''
    results.each do |result|
      text += ' <span class=section1><u>'+bodySection.body["1"]+'</u></span>,' if result["name"]=='Visão' && result["value"] <= min_value
      text += ' <span class=section2><u>'+bodySection.body["2"]+'</u></span>,'if result["name"]=='Competência' && result["value"] <= min_value
      text += ' <span class=section3><u>'+bodySection.body["3"]+'</u></span>,' if result["name"]=='Recursos' && result["value"] <= min_value
      text += ' <span class=section4><u>'+bodySection.body["4"]+'</u></span>,' if result["name"]=='Infraestrutura' && result["value"] <= min_value
   end
    text
  end

  def count_worst_section
    scores = []
    results.each do |result|
      scores.push(result["value"])
    end
    min_value = scores.min
    scores.count(min_value)
  end

  def update_school_levels
    return true unless school.present?
    school.update_levels(self)
  end

  def decrease_number_of_tries_left
    without_callback(:save, :after, :update_school_levels) do
      update number_of_tries_left: number_of_tries_left - 1
    end
  end

  def reset_number_of_tries
    without_callback(:save, :after, :update_school_levels) do
      update number_of_tries_left: RESET_NUMBER_OF_RETRIES
    end
  end

  def set_not_in_use
    without_callback(:save, :after, :update_school_levels) do
      update in_use: false
    end
  end

  def set_in_use
    without_callback(:save, :after, :update_school_levels) do
      update in_use: true
    end
  end

  def is_combined
    if !self.type.nil?
      if self.type == 'Combined'
        return true
      else
        return false
      end
    else
      return false
    end
  end

  memoize :section_scores

  protected
  def without_callback(*args)
    self.class.skip_callback(*args)
    yield
    self.class.set_callback(*args)
  end
end
