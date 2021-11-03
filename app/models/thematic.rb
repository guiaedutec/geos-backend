class Thematic
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String

  # Validations
  validates :name, presence: true

  # Relationships
  belongs_to  :survey,             validate: true
  belongs_to  :survey_section,     validate: true

  scope :ordered, -> { order(:survey_section.asc) }

  def to_s
    "#{name}/#{descripton}"
  end
end
