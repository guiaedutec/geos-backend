class Country
    include Mongoid::Document
    include Mongoid::Timestamps
  
    field :name, type: String
    field :geo_structure_level1_name, type: String
    field :geo_structure_level2_name, type: String
    field :geo_structure_level3_name, type: String
    field :geo_structure_level4_name, type: String
    
    validates :name, presence: true, uniqueness: true
  
  end
  