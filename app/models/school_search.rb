class SchoolSearch
  attr_accessor :query, :sort_field, :sort_direction, :filters, :state, :city, :limit, :type, :state_id, :province_id, :country_id
  attr_reader :schools, :page_answers

  FILTERS = %w(vision_level competence_level resource_level infrastructure_level sample answered).freeze

  def initialize(query: nil, sort_field: nil, sort_direction: nil, state: nil, city: nil, page: nil, type: nil, limit: nil, complete: nil, state_id: nil, province_id: nil, country_id: nil)
    @schools = complete ?  School.includes(:state, :school_infra) : @schools = School.all
    @sort_direction = sort_direction.to_s == 'desc' ? -1 : 1
    @sort_field = sort_field
    @state = state
    @city = city
    @type = type
    @state_id = state_id
    @province_id = province_id
    @country_id = country_id
    @query = query
    @page = page || 1
    @limit = limit

    filter_by_type
    filter_by_query
    filter_by_state
    filter_by_city
    order_schools
    paginate_answers
  end

  def filter_by_query
    @schools = @schools.full_text_search(query) if @query.present?
  end

  def filter_by_state
    @schools = @schools.where(:city_id.in => @state.cities.pluck(:_id)) if @state.present?
  end

  def filter_by_city
    if @city
      @schools = @schools.where(:city_id => @city._id,
                                :state_id => BSON::ObjectId.from_string(@state_id),
                                :province_id => BSON::ObjectId.from_string(@province_id),
                                :country_id => BSON::ObjectId.from_string(@country_id))
    end
  end

  def filter_by_type
    @schools = @schools.where(:type => @type) if @type.present?
  end

  def order_schools
    @schools =  case @sort_field
                when nil
                  @schools.order(:answered.desc)
                when 'answered'
                  @schools.order(answered: @sort_direction)
                when 'inep'
                  @schools.order(inep_code: @sort_direction)
                when 'school_name'
                  @schools.order(name: @sort_direction)
                when 'school_city'
                  @schools.order(city_name: @sort_direction)
                when 'school_state'
                  @schools.order(state_name: @sort_direction)
                else
                  @schools.order(@sort_field => @sort_direction)
                end
  end

  def paginate_answers
    lim = 50
    if @limit
      lim = @limit
    end
    @page_answers = @schools
  end

  def pages_count
    1
  end

  def total_count
    @schools.count
  end

  def answered_count
    @schools.with_response.count
  end

  def total_sample_count
    @schools.where(sample: true).count
  end

  def answered_sample_count
    @schools.with_response.where(sample: true).count
  end
end