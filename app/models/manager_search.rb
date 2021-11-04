class ManagerSearch
  attr_accessor :query, :sort_field, :sort_direction
  attr_reader :page_answers

  FILTERS = %w(vision_level competence_level resource_level infrastructure_level sample answered).freeze

  def initialize(query: nil, sort_field: nil, sort_direction: nil, state: nil, city: nil, regional: nil, filters: nil, type: nil, page: nil, limit: nil, institution: nil)

    if(limit)
      @managers = Manager
    else
      @managers = Manager.includes(:schools)
    end

    @sort_direction = sort_direction.to_s == 'desc' ? -1 : 1
    @sort_field = sort_field
    @filters = filters || {}
    @state = state
    @city = city
    @type = type
    @regional = regional
    @query = query
    @page = page || 1
    @limit = limit
    @institution = institution

    filter_by_query
    filter_by_type
    filter_by_state
    filter_by_city
    filter_by_institution
    order_answers
    paginate_answers
  end

  def filter_by_query
    @managers = @managers.full_text_search(query) if @query.present?
  end

  def order_answers
    @managers =  case @sort_field
                when nil
                  @managers.order(:nome.desc)
                when 'email'
                  @managers.order(email: @sort_direction)
                when 'inep'
                  @managers.order(inep_code: @sort_direction)
                else
                  @managers.order(@sort_field => @sort_direction)
                end
  end

  def paginate_answers
    lim = 50
    if @limit
      lim = @limit
    end

    @page_answers = @managers
  end

  def filter_by_type
    @managers = @managers.where(:type => @type) if @type.present?
  end

  def filter_by_state
    @managers = @managers.where(:state_id => @state) if @state.present?
  end

  def filter_by_city
    @managers = @managers.where(:city_id => @city) if @city.present?
  end

  def filter_by_institution
    @managers = @managers.where(:institution_id => @institution) if @institution.present?
  end

  def limit
    @limit
  end

  def pages_count
    1
  end

  def total_count
    @managers.count
  end

  def answered_count
    @managers.with_response.count
  end

  def total_sample_count
    @managers.where(sample: true).count
  end

  def answered_sample_count
    @managers.with_response.where(sample: true).count
  end
end
