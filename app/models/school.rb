class School
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Search
  include Mongoid::Attributes::Dynamic

  field :id,                type: BSON::ObjectId
  field :country_id, type: BSON::ObjectId
  field :province_id, type: BSON::ObjectId
  field :name, type: String # no_entidade in spreadsheet
  field :affiliation_id,    type: BSON::ObjectId
  field :affiliation_name,  type: String
  field :level_1_name,      type: String
  field :level_2_name,      type: String
  field :level_3_name,      type: String
  field :level_4_name,      type: String
  field :type_institution,  type: String
    
  field :inep_code, type: String # co_entidade in spreadsheet
  field :staff_count, type: Integer
  field :staff_observations, type: String
  field :student_diurnal_count, type: Integer, default: 0
  field :student_vespertine_count, type: Integer, default: 0
  field :student_nocturnal_count, type: Integer, default: 0
  field :student_full_count, type: Integer, default: 0
  field :kindergarten, type: Mongoid::Boolean, default: false
  field :elementary_1, type: Mongoid::Boolean, default: false
  field :elementary_2, type: Mongoid::Boolean, default: false
  field :highschool, type: Mongoid::Boolean, default: false
  field :technical, type: Mongoid::Boolean, default: false
  field :adult, type: Mongoid::Boolean, default: false
  field :regional, type: String

  field :student_observations, type: String
  field :private, type: Mongoid::Boolean
  field :type, type: String
  field :location_type, type: String
  field :sample, type: Mongoid::Boolean, default: false
  field :observations, type: String, default: ''

  field :survey_start_date, :type => Date
  field :survey_end_date, :type => Date
  field :missing_days, type: :integer

  field :city_name, type: String
  field :state_name, type: String
  field :path_images, type: String
  field :plan, type: Array
  field :scenario, type: Object

  # de-normalized fields from survey_response
  field :vision_level, type: :integer
  field :competence_level, type: :integer
  field :resource_level, type: :integer
  field :infrastructure_level, type: :integer
  field :answered, type: Mongoid::Boolean, default: false
  field :results, type: Hash
  field :num_responses, type: Integer, default: 0
  field :school_infra,  type: Object
  field :manager,  type: Object

  field :active, type: Mongoid::Boolean, default: true
  default_scope -> { where(active: true) }

  scope :ordered, -> { order(:name.asc) }
  scope :with_response, -> { where(answered: true) }
  scope :with_plan, -> { where(:plan.exists => true) }

  # Validations

  # Relationships
  has_many    :survey_responses, dependent: :destroy, validate: false, autosave: true
  belongs_to  :city, optional: true
  belongs_to  :state, optional: true
  belongs_to  :manager, optional: true, autosave: true
  has_many    :users, validate: false
  has_one     :school_infra, validate: false, autosave: true, dependent: :destroy

  search_in :name, :inep_code, :city_name, :state_name, :regional

  field :chosen, type: Mongoid::Boolean, default: false
  field :value_raffle, type: Float, default: 0
  field :order_raffle, type: Integer, default: 0

  field :is_school_imported, type: Mongoid::Boolean, default: false

  def with_response survey_schedule_id=nil
    if !survey_schedule_id.nil?
      School.where(:"results.#{survey_schedule_id}.answered" => true)
    else
      set = { '$set' => {
                :rr => {"$last" => { "$objectToArray": "$results" }}
      }}

      match = { '$match' => {
                  :results => { '$exists' => true },
                  :'rr.v.answered' => true
      } }

      School.collection.aggregate([set, match])
    end
  end

  def oldest_survey_response
    return nil unless survey_responses.complete.exists?
    survey_responses.complete.last
  end

  def update_levels(survey_response)
    return unless survey_response && survey_response.survey && survey_response.survey.type === "school" && survey_response.status == 'Complete'
    if(!survey_response.invited_teacher && survey_response.type != "Combined")
      self.num_responses = 1
      survey_responses.select{|r|
        r.status == 'Complete' &&
        r.survey_schedule_id == survey_response.survey_schedule.id &&
        r.id != survey_response.id
      }.each(&:set_not_in_use)
    end
    
    if !survey_response.survey_schedule_id.nil?
      survey_schedule_id = survey_response.survey_schedule.id.to_s
      results = Hash.new
      if self.results.nil?
        results[survey_schedule_id] = Hash.new
      else
        results = self.results
      end

      if results[survey_schedule_id].nil?
        results[survey_schedule_id] = Hash.new
      end

      results[survey_schedule_id]["answered"] = true
      results[survey_schedule_id]["student_diurnal_count"] = self.student_diurnal_count
      results[survey_schedule_id]["student_vespertine_count"] = self.student_vespertine_count
      results[survey_schedule_id]["student_nocturnal_count"] = self.student_nocturnal_count
      results[survey_schedule_id]["student_full_count"] = self.student_full_count

      if !survey_response.results.nil?
        survey_response.results.each do |result|
          case result["name"]
          when 'Visão' then results[survey_schedule_id]["vision_level"] = result["value"]
          when 'Competência' then results[survey_schedule_id]["competence_level"] = result["value"]
          when 'Recursos' then results[survey_schedule_id]["resource_level"] = result["value"]
          when 'Infraestrutura' then results[survey_schedule_id]["infrastructure_level"] = result["value"]
          end
        end
      else
        results[survey_schedule_id]["vision_level"] = survey_response.vision_level
        results[survey_schedule_id]["competence_level"] = survey_response.competence_level
        results[survey_schedule_id]["resource_level"] = survey_response.resource_level
        results[survey_schedule_id]["infrastructure_level"] = survey_response.infrastructure_level
      end
      puts "results saved"
      self.results = results
    end

    in_use = true
    if(survey_response.invited_teacher)
      combined_surveys = survey_responses.select{|r| r.status == 'Complete' && r.type == "Combined" && r.survey_schedule_id == survey_response.survey_schedule.id }
      if combined_surveys.size() == 1
        in_use = combined_surveys.first.in_use
      else
        combined_surveys.each do |response|
          if response.guests.select{|guest| guest[:survey_response_id] == survey_response.id}.size() > 0
            in_use = response.in_use
          end
        end
      end
      if in_use
        self.num_responses += 1
      end
    end
    if survey_response.type == "Combined"
      in_use = survey_response.in_use
    end
    if in_use
      survey_response.set_in_use
    end

    self.save
  end

  def student_count
    student_diurnal_count.to_i +
      student_vespertine_count.to_i +
      student_nocturnal_count.to_i +
      student_full_count.to_i
  end

  def max_shift_students
    [student_diurnal_count, student_vespertine_count, student_nocturnal_count, student_full_count].map(&:to_i).max
  end

  def manager_name
    manager.name if manager
  end

  def manager_phone
    manager.phone if manager
  end

  def manager_email
    manager.email if manager
  end

  def responses
    return unless survey_responses.exists?
    results = Array.new
    survey_responses.inuse.each do |response|
      response.response_answers.push(response.fetch_responses)
      results.push(response)
    end
    results
  end

  def set_state_by_city
    return if city.blank?
    self.state = city.state
  end

  def survey
    state ? state.get_survey : Survey.default
  end

  def base_survey_url
    survey.url
  end

  def to_s
    name
  end
  def type
    type_institution
  end

  alias survey_response oldest_survey_response

protected
  def set_city_name
    return unless city.present?
    self.city_name = city.name
  end

  def set_state_name
    return unless state.present?
    self.state_name = state.name
  end

end