# encoding: utf-8
class FeedbackImgUploader < BaseUploader
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:

  def size_range
    1..2.megabytes
  end
end
