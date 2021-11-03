class Translation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic #Dynamic fields
  include Mongoid::Timestamps
  field :lang, type: String
end
