class UserActivity
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: Integer
  field :activity_id, type: Integer
  field :type, type: String
  field :affiliation_id, type: BSON::ObjectId 

  belongs_to :user
  belongs_to :activity

end
