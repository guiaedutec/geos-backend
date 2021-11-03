class SchoolRegionalsSearch
  attr_accessor :state, :city, :type
  attr_reader :schools

  def initialize(query: nil, sort_field: nil, sort_direction: nil, state: nil, city: nil, page: nil, type: nil, limit: nil)
    @schools = School
    @state = state
    @city = city
    @type = type

    filter_by_type
    filter_by_state
    filter_by_city
    filter_null
    distinct_regional
  end

  def filter_by_state
    @schools = @schools.where(:city_id.in => @state.cities.pluck(:_id)) if @state.present?
  end

  def filter_by_city
    @schools = @schools.where(:city_id => @city._id) if @city.present?
  end

  def filter_by_type
    @schools = @schools.where(:type => @type) if @type.present?
  end

  def filter_null
    @schools = @schools.where(:regional.nin => [nil,''])
  end

  def distinct_regional
    @schools = @schools.distinct(:regional)
  end

end