class SurveySchedule
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :type, type: String
  field :survey_start_date, :type => Time
  field :survey_end_date, :type => Time
  field :missing_days, type: :integer
  field :recurrence_days, type: Integer
  field :affiliation_id, type: BSON::ObjectId

  belongs_to :state
  belongs_to :survey

  scope :created_order, -> { order(:created_at.asc) }
  scope :invese_created_order, -> { order(:created_at.desc) }

  def set_rdn_sample user=nil
    survey_schedule_id=self._id

    return false if user.nil?

    valid = true
    begin
      str = nil
      count = nil
      scArray = nil

      if (!user['profile'].nil? && (user['profile'].to_s != "teacher" && user['profile'].to_s != "principal"))
        scArray = School.where(:affiliation_id => user.affiliation_id)
      end

      if scArray.nil?
        return false
      end

      survey_schedule_id = scArray.first.results.keys.last if survey_schedule_id.nil?

      aux_sample = scArray.where(:"results.#{survey_schedule_id}.sample" => true)
      already_sample = aux_sample.nil? ? false : (aux_sample.length > 0 ? true : false)

      return false if already_sample

      scArray.update_all({:"results.#{survey_schedule_id}.sample" => false})
      user.update_attributes(:school_validate => false)
      count = scArray.length
      arrayList = nil
      number_schools = calculate_number_schools(count)
      arrayList = scArray.sample(number_schools)
      rankSchools = sort_schools(scArray)

      idsSample = []
      rankSchools.each_with_index do |rs, index|
        objectId = rs[0].to_s.split(':')[1]
        if (index < number_schools)
          idsSample.push(objectId)
        end
      end

      aux = School.where(_id:{"$in" => idsSample})
      if !aux.nil?
        aux.update_all(:"results.#{survey_schedule_id}.sample" => true)
        user.update_attributes(:school_validate => true)
      else
        valid = false
      end
    rescue Exception => e
      valid = false
      Rails.logger.error "generating samples"
      Rails.logger.error e.backtrace.join("\n")
      Rails.logger.error e
      Rails.logger.error e.backtrace
    end

    return valid
  end

  def calculate_number_schools(size_schools)
    total = 1.3*(size_schools*(1.96**2)*(0.5**2))/((size_schools-1)*(0.1**2)+(1.96**2)*(0.5**2))
    return total.round
  end

  def sort_schools(schools)
    schoolArray = []
    schools.each do |s|
      ran = rand(0.0...10.0)
      schoolArray.push([ ":" + s.id.to_s, ran])
    end
    schoolArray = schoolArray.sort {|a,b| a[1] <=> b[1]}
    return schoolArray
  end

end