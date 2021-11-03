class SurveyQuestion
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, localize: true
  field :question_order, type: String
  field :position, type: Integer
  field :type, type: String
  field :survey_question_description, type: Array, localize: true
  field :state, type: String
  field :city, type: String
  field :type_role, type: String
  field :page, type: Integer
  field :weight, type: Float
  field :obs, localize: true
  field :only_principal, type: Boolean
  field :has_child, type: Boolean
  field :compound, type: Boolean
  field :compound_ref, type: String
  field :compound_first, type: Boolean
  field :not_normalize, type: Boolean

  has_many :survey_responses, dependent: :destroy
  has_many :response_answeres, dependent: :destroy

  belongs_to :survey_section
  belongs_to :survey

  before_save :set_survey

  scope :main, -> { where(main_question_id: nil) }
  scope :ordered, -> { order(:survey_id.asc, :survey_section_id.asc, :main_question_id.asc, :position.asc) }

  def open_answer?
    !%w(checkbox radio text table).include?(type)
  end

  def computer_count_question?
    return false unless survey_section && survey_section.survey
  end

  def normalise_score_ratio
    ratio = 0;
    if (type == 'radio')
      if !survey_question_description.nil?
        ratio = survey_question_description.sort_by{|v| v["weight"]}.last["weight"]
      end
    elsif (type == 'checkbox' || type == 'table')
      if !survey_question_description.nil?
        survey_question_description.each_with_index do |sqd, index|
          if !sqd["weight"].nil?
            ratio += sqd["weight"]
          else
            ratio = 0
          end
        end
      end
    elsif (type == 'pc')
      ratio = 6
    end
    if(weight !=0 && ratio != 0)
      ratio = 3.0/(ratio * weight)
    else
      if(ratio != 0)
        ratio = (3.0/ratio)
      end
    end
    return  ratio
  end

protected
  def set_survey
    self.survey = survey_section.survey if survey_section
  end
end
