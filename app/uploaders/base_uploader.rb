class BaseUploader < CarrierWave::Uploader::Base
  # Choose what kind of storage to use for this uploader:
  #storage :fog

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end
end
