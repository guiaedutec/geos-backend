class VirtualFile < StringIO
  attr_accessor :original_filename

  def initialize(string, original_filename)
    @original_filename = original_filename
    super(string)
  end
end
