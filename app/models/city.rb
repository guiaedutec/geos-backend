class City
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :capital, type: Mongoid::Boolean, default: false
  field :ibge_code, type: String
  field :country_id, type: BSON::ObjectId
  field :country_name, type: String
  field :province_id, type: Object
  field :province_name, type: String
  field :state_id, type: Object
  field :state_name, type: String

  # Validations
  validates :name, presence: true

  # Relationships
  has_many    :users,             validate: false
  has_many    :schools,           validate: false
  has_many    :survey_schedules,  validate: false
  has_many    :devolutive_img,    validate: false

  def uf_ibge_code
    return nil unless ibge_code.present?
    ibge_code[0..1]
  end

  def to_s
    "#{name}/#{state}"
  end
end
