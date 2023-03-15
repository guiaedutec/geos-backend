class Feedback
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, localize: true
  field :subtitle, localize: true
  field :body, type: Hash, localize: true
  field :page, type: Integer
  field :tag, type: String
  field :type, type: String
  field :level, type: String
  field :group, type: Hash, localize: true
  field :report, type: Hash, localize: true
  
  belongs_to  :survey
  belongs_to :survey_section
end
