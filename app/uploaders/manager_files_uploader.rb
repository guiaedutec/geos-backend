# encoding: utf-8
class ManagerFilesUploader < BaseUploader
  # Add a white list of extensions which are allowed to be uploaded.
  def extension_white_list
    %w(pdf png doc docx)
  end

  # Define max size of uploaded file
  def size_range
    1..5.megabytes
  end
end
