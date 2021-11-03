class Language
  include Mongoid::Document
  include Mongoid::Timestamps
  field :lang, type: String
  field :description, type: String
  field :flag, type: String
  field :display, type: Boolean
end
