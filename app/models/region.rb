class Region
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :provincias, type: Array
  field :direccion_regional_id, type: Integer

  validates :name, presence: true, uniqueness: true

  has_many :states

  def to_s
    name
  end
end
