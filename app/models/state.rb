class State
  include Mongoid::Document
  include Mongoid::Timestamps

  field :acronym, type: String
  field :name, type: String
  field :provincia_id, type: Object
  field :canton_id, type: Integer
  field :country_id, type: BSON::ObjectId
  field :country_name, type: String
  field :province_id, type: Object
  field :province_name, type: String

  # Validations
  validates :name, presence: true

  # Relationships
  has_many :cities, validate: false
  has_many :devolutive_img, validate: false
  has_many :schools
  has_many :survey_schedules
  has_one :survey

  def self.find_by_acronym(accr)
    where(acronym: accr).first
  end

  def to_s
    acronym
  end

  def get_survey
    survey || Survey.default
  end
end
