class Province
    include Mongoid::Document
    include Mongoid::Timestamps
  
    field :name, type: String
    field :country_id, type: BSON::ObjectId
    field :country_name, type: String
  
  end
  