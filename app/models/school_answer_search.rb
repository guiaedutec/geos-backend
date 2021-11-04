class SchoolAnswerSearch
  attr_accessor :query, :sort_field, :sort_direction, :filters, :state ,:asc,:tsc,:ac,:tc,:pc
  attr_reader :answers, :page_answers, :page_details

  FILTERS = %w(vision_level competence_level resource_level infrastructure_level sample answered).freeze

  def initialize(query: nil, sort_field: nil, sort_direction: nil, state: nil, regional: nil, type: nil, city: nil, filters: nil, page: nil, survey_schedule_id: nil, affiliation_id: nil, rf: true)
    @answers = School.includes(:manager)
    @sort_direction = sort_direction.to_s == 'desc' ? -1 : 1
    @sort_field = sort_field
    @filters = filters || {}
    @state = state
    @city = city
    @type = type
    @regional = regional
    @query = query
    @page = page || 1
    @survey_schedule_id = survey_schedule_id
    @affiliation_id = affiliation_id
    @flag_results_exists = rf

    filter_by_query
    filter_by_state
    filter_by_city
    filter_by_regional
    filter_by_type

    assert_results_exists if @flag_results_exists
    default_survey_schedule_id if @flag_results_exists

    filter_by_affiliation
    
    filter_answers
    filter_planned
    order_answers
    paginate_answers
    paginate_details
  end

  def default_survey_schedule_id
    if @survey_schedule_id.nil?
      aux = @answers[0].results.to_hash
      @survey_schedule_id = aux.keys.last
    end
  end

  def assert_results_exists
    @answers.each do |answer|
      if answer.results.nil?
        @flag_results_exists = false
        return
      elsif answer.results["#{@survey_schedule_id}".to_sym].nil?
        @flag_results_exists = false
        return
      end
    end
  end

  def filter_by_query
    @answers = @answers.full_text_search(query) if @query.present?
  end

  def filter_by_state
    @answers = @answers.where(:city_id.in => @state.cities.pluck(:_id)) if @state.present?
  end

  def filter_by_city
    @answers = @answers.where(:city_id => @city._id) if @city.present?
  end

  def filter_by_type
    @answers = @answers.where(:type => @type) if @type.present?
  end

  def filter_by_regional
    @answers = @answers.where(regional: @regional) if @regional.present?
  end

  def filter_by_affiliation
    @answers = @answers.where(affiliation_id: @affiliation_id) if @affiliation_id.present?
    puts @answers.inspect
  end

  def filter_answers
    values_already_searched = Array.new
    @filters.each do |field_name, values|
      next unless FILTERS.include?(field_name.to_s)
      case field_name.to_s
      when /^(vision|competence|resource|infrastructure)_level$/
        @answers = @answers.where(:"results.#{@survey_schedule_id}.#{field_name.to_sym}" => { "$in" => values.map(&:to_i) })
      when 'answered'
        if values == ['true'] || values == [true]
          @answers = @answers.where(:"results.#{@survey_schedule_id}.answered" => true)
        elsif values == ['false'] || values == [false]
          @answers = @answers.where(:"results.#{@survey_schedule_id}.answered" => false)
        end
      when 'sample'
        if values == ['true'] || values == [true]
          @answers = @answers.where(:"results.#{@survey_schedule_id}.sample" => true)
        elsif values == ['false'] || values == [false]
          @answers = @answers.where(:"results.#{@survey_schedule_id}.sample" => false)
        end
      else
        @answers = @answers.where(field_name.to_sym.in => values)
      end
    end
  end

  def filter_planned
    @filters.each do |field_name, values|
      if field_name.to_s == 'planned'
        if values == ['true'] || values == [true]
          @answers = @answers.where(:plan.exists => true)
        elsif values == ['false'] || values == [false]
          @answers = @answers.where(:plan.exists => false)
        end
      end
    end
  end

  def order_answers
    @answers =  case @sort_field
    when nil
      @answers.order(:"results.#{@survey_schedule_id}.answered".desc)
    when 'answered'
      @answers.order(:"results.#{@survey_schedule_id}.answered" => @sort_direction)
    when 'planned'
      @answers.order(plan: @sort_direction)
    when 'sample'
      @answers.order(sample: @sort_direction)
    when 'inep'
      @answers.order(inep_code: @sort_direction)
    when 'school_name'
      @answers.order(name: @sort_direction)
    when 'school_city'
      @answers.order(city_name: @sort_direction)
    else
      @answers.order(@sort_field => @sort_direction)
    end
  end

  def to_xls(file)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: 'Acompanhamento de Respostas'
    sheet.row(0).concat xls_header
    @answers.each.with_index do |answer, i|
      add_xls_row(sheet.row(i + 1), answer)
    end
    book.write(file)
  end

  def xls_header
    [
      'Amostra',
      'Respondeu?',
      'Código INEP',
      'Escola',
      'Município',
      'Regional',
      'Nível Visão',
      'Nível de Competência',
      'Nível de Recursos',
      'Nível de Infraestrutura',
      'Nome do diretor',
      'Email do diretor',
      'Telefone do diretor',
      'Observações'
    ]
  end

  def add_xls_row(row, school)
    puts "school.id "
    puts school.inspect
    puts "survey_schedule_id "
    puts @survey_schedule_id
    row.push school.sample ? 'Sim' : 'Não'
    row.push school.answered? ? 'Sim' : 'Não'
    row.push school.inep_code
    row.push school.name
    row.push school.city.name
    row.push school.regional
    if (school.results.present?)
      row.push school.results["#{@survey_schedule_id}"]['vision_level'].to_s
      row.push school.results["#{@survey_schedule_id}"]['competence_level'].to_s
      row.push school.results["#{@survey_schedule_id}"]['resource_level'].to_s
      row.push school.results["#{@survey_schedule_id}"]['infrastructure_level'].to_s
    else 
      row.push ""
      row.push ""
      row.push ""
      row.push ""
    end
    row.push school&.manager&.name.to_s
    row.push school&.manager&.email.to_s
    row.push school&.manager&.phone.to_s
    row.push school.observations
  end

  def paginate_answers
    lim = 50
    if @limit
      lim = @limit
    end   
    @page_answers = @answers
  end

  def paginate_details
    @page_details = @answers
  end

  def pages_count
    1
  end

  def pages_details_count
    1
  end

  def total_count
    @answers.count
  end

   def answered_count
     count = 0
     @answers.each { |answer| 
      count += 1 if !answer.results.nil? and !answer.results["#{@survey_schedule_id}".to_sym].nil? and answer.results["#{@survey_schedule_id}".to_sym]['answered'] 
    }
     count
   end

  def planned_count
    @answers.with_plan.count
  end

   def total_sample_count
     count = 0
     @answers.each { |answer| count += 1 if !answer.results.nil? and !answer.results["#{@survey_schedule_id}".to_sym].nil? and answer.results["#{@survey_schedule_id}".to_sym]['sample'] }
     count
   end

   def answered_sample_count
     count = 0
     @answers.each { |answer| count += 1 if !answer.results.nil? and !answer.results["#{@survey_schedule_id}".to_sym].nil? and answer.results["#{@survey_schedule_id}".to_sym]['sample'] and answer.results["#{@survey_schedule_id}".to_sym]['answered'] }
     count
   end


end
