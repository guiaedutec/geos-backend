class Parameter
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic #Dynamic fields
  include Mongoid::Timestamps

  field :imgLogoHeader, type: String
  field :imgLogoHeaderSec, type: String
  field :imgLogoFooter, type: String
  field :imgLogoFooterSec, type: String
  field :imgBgHome, type: String

  field :styleSCSS, type: String
  field :styleVars, type: String
  field :colorPrimary, type: String
  field :colorSecondary, type: String

  field :setupIsDone, type: Mongoid::Boolean, default: false

  validates :imgLogoHeader, presence: true
  validates :imgLogoFooter, presence: true
  validates :colorPrimary, presence: true
  validates :colorSecondary, presence: true

  def done
    update_attribute(:setupIsDone, true)
  end
end
