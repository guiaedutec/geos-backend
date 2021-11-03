class ManagerFile
  include Mongoid::Document
  include Mongoid::Timestamps

  field :affiliation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  mount_uploader :file_upload, ManagerFilesUploader

end
