class SchoolInfra
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :comp_admins, type: Integer, default: 0
  field :comp_teachers, type: Integer, default: 0
  field :comp_students, type: Integer, default: 0
  field :printers, type: Integer, default: 0
  field :rack, type: Integer, default: 0
  field :nobreak, type: Integer, default: 0
  field :switch, type: Integer, default: 0
  field :firewall, type: Integer, default: 0
  field :wifi, type: Integer, default: 0
  field :projector, type: Integer, default: 0
  field :server, type: Integer, default: 0
  field :charger, type: Integer, default: 0
  field :maker, type: Integer, default: 0

  field :is_imported, type: Mongoid::Boolean, default: false

  # Relationships
  belongs_to  :school

end


