class Manager
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Search

  has_many :schools

  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :type, type: String
  field :is_principal_profile_imported, type: Mongoid::Boolean, default: false

  field :institution,                type: Object

  # Validations
  validates :email, uniqueness: { allow_blank: true }
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  validates :name, presence: true
  validates :type, presence: true
  validates :institution, presence: true



  # Relationships
  #belongs_to  :state
  #belongs_to  :city
  belongs_to :institution

  search_in :name, :email, :phone
end
