class Provincia
    include Mongoid::Document
    include Mongoid::Timestamps
  
    field :provincia_id, type: Integer
    field :name, type: String
  
    validates :name, presence: true
  
    def to_s
      name
    end
  end