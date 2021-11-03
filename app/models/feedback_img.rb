class FeedbackImg
  include Mongoid::Document
  include Mongoid::Timestamps

  field :type, type: String
  field :affiliation_id,      type: BSON::ObjectId
  mount_uploader :file_upload, FeedbackImgUploader

  belongs_to  :city
  belongs_to  :state
end
