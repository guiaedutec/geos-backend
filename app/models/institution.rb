class Institution
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic #Dynamic fields
  include Mongoid::Timestamps
  include Mongoid::Search

  field :id, type: BSON::ObjectId
  field :name, type: String
  field :type_institution, type: String
  field :type, type: String
  field :country_id, type: BSON::ObjectId
  field :country_name, type: String
  field :province_id, type: BSON::ObjectId
  field :province_name, type: String
  field :state_id, type: BSON::ObjectId
  field :state_name, type: String
  field :city_id, type: BSON::ObjectId
  field :city_name, type: String

  field :plans,type: Array
  field :amount_teachers, type: Integer

  # Validations
  validates :name, presence: true

  # Relationships
  has_many    :users, validate: false
  has_many    :managers

  def to_s
    "#{name}/#{country_name}"
  end

  def type
    type_institution
  end

  private
  def amount_teachers

    group = { '$group' => { :_id => 0, :a_t => { '$sum' => '$staff_count' } } }
    match = { '$match' => { :affiliation_id=> self._id } }

    amount = School.collection.aggregate([match, group])

    return !amount.nil? ? amount.first : nil
  end
end