# encoding: utf-8
class SurveyQuestionsUploader < BaseUploader
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(pdf)
  end
end
