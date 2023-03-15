class User
  include Mongoid::Document
  include Mongoid::EnumAttribute
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include Mongoid::Search
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  attr_accessor :inep_code

  devise  :database_authenticatable,
          :registerable,
          :recoverable,
          :rememberable,
          :trackable,
          :validatable

  ## Custom fields
  field :id,                         type: BSON::ObjectId
  field :name,                       type: String, default: ''
  field :cpf,                        type: String
  field :born,                       type: Date
  field :authenticity_token,         type: String, default: ''
  field :role,                       type: String, default: ''
  field :responsible_name,           type: String, default: ''
  field :responsible_email,          type: String, default: ''
  field :responsible_phone_number,   type: String, default: ''
  field :type,                       type: String, default: ''
  field :stages,                     type: Array
  field :knowledges,                 type: Array
  field :origin,                     type: String
  field :invited_survey,             type: Array
  field :term,                       type: Boolean
  field :sharing,                    type: Boolean
  field :formation,                  type: Boolean
  field :formation_level,            type: Hash
  field :manager_file,               type: Object
  field :phone_number,               type: String
  
  enum :profile, [:principal, :other, :teacher, :admin, :admin_state, :admin_city, :monitor_state, :monitor_city, :monitor_state_regional, :monitor_city_regional, :admin_country]

  ## Database authenticatable
  field :email,                      type: String, default: ''
  field :encrypted_password,         type: String, default: ''

  ## Recoverable
  field :reset_password_token,       type: String
  field :reset_password_sent_at,     type: Time

  ## Rememberable
  field :remember_created_at,        type: Time

  ## Trackable
  field :sign_in_count,              type: Integer, default: 0
  field :current_sign_in_at,         type: Time
  field :last_sign_in_at,            type: Time
  field :current_sign_in_ip,         type: String
  field :last_sign_in_ip,            type: String


  field :school_valid,               type: Boolean, default: true
  field :institutions_admin,         type: Array
  field :was_notified,               type: Boolean
  field :school,                     type: Object
  field :institution,                type: Object
  field :affiliation_id,             type: BSON::ObjectId
  field :country_id,                 type: BSON::ObjectId
  field :province_id,                type: BSON::ObjectId
  field :affiliation_name,           type: String  
  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time
  field :locked,          type: Boolean, default: false

  field :regional, type: String
  default_scope -> { where(active: true) }

  # Validations
  validates :name, :profile, presence: true
  validates :authenticity_token, uniqueness: true
  validates :school_id, presence: true, if: -> (u) { u.principal? || u.teacher? }
  
  validates :state_id, presence: true, if: ->(u) { u.admin_city? }
  validates :regional, presence: true, if: ->(u) { u.monitor_regional? }
  #validates :regional, presence: true, if: :monitor_regional?

  # Relationships
  # belongs_to :state # profiles other than principal do not have city, only state
  # belongs_to :city
  belongs_to :school, optional: true
  belongs_to :institution, optional: true
  #belongs_to :manager_file

  mount_uploader :response, ResponsePdfUploader

  # Scopes
  scope :by_city, -> (city) { where(city: city) }
  scope :principal_or_teacher, -> { where(:_profile.in => [:principal, :teacher]) }
  #default_scope -> { order(:created_at.asc) }

  ## Callbacks
  before_save :ensure_authentication_token
  before_validation :associate_inep_to_school
  has_one :survey_response

  # Search
  search_in :name, :email

  def manager_file
    if self.admin_state?
      files = ManagerFile.where(user_id: _id)
      return files
    else
      return nil
    end
  end

  def self.without_response
    complete_user_ids = SurveyResponse.complete.pluck(:user_id)
    deleted_user_ids = SurveyResponse.deleted.pluck(:user_id)
    User.nin(id: complete_user_ids + deleted_user_ids)
  end

  def admin?
    %w(admin admin_state admin_city).include? profile.to_s
  end

  def admin_country?
    %w(admin_country).include? profile.to_s
  end

  def super_admin?
    %w(admin).include? profile.to_s
  end

  def other?
    %w(other).include? profile.to_s
  end

  def monitor_regional?
    %w(monitor_state_regional monitor_city_regional).include? profile.to_s
  end

  def institution_type
    self.institution.type
  end

  def has_answered_survey
    school.present? && school.answered?
  end

  def inep_code
    return '' unless school.present?
    school.inep_code
  end

  def survey
    state ? state.get_survey : Survey.default
  end

  def destroy
    update_attribute(:deleted_at, Time.current)
    update_attribute(:email, self.email + "-deleted-" + Time.current.to_s)
    update_attribute(:active, false)
  end

  def active_for_authentication?
    super && !self.locked
  end
  
  private
  def generate_authentication_token!
    loop do
      token = Devise.friendly_token
      break token unless User.where(authenticity_token: token).first
    end
  end

  def ensure_authentication_token
    self.authenticity_token = generate_authentication_token! if authenticity_token.blank?
  end

  def associate_inep_to_school
    return if @inep_code.blank? || !School.where(inep_code: @inep_code).exists?
    self.school = School.find_by(inep_code: @inep_code)
  end

  ## Custom Validations
end
