class Activity
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :description, type: String
  field :title_file_upload, type: String
  field :file_upload, type: String

  field :is_state , type: Mongoid::Boolean, default: false
  field :type, type: String

  # Validations

  before_save :save_dashboard

  validates :description, presence: true, length: { maximum: 512 }
  validates :title, presence: true, length: { maximum: 256 }
  validates :title_file_upload, length: { maximum: 256 }
  validates :title_file_upload, presence: true, if: -> { !'file_upload.blank?' }
  validate :file_size
  before_save :save_dashboard

  def file_size
    if (!file_upload.file.nil?)
      size = file_upload.file.size.to_f/(1024*1024).round
      if (size > 2)
        errors.add :file_upload, 'O arquivo não pode ser maior que 2Mb.'
      end
    end
  end
end
