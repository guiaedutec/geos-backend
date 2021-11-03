class Dash

  attr_accessor :answered_sample_count, :is_school_imported, :other_profile_count, :principal_profile_count, :network_type, :teacher_profile_count, :is_principal_profile_imported, :is_sample_school_generated,:activity_checklist, :help_people_count, :is_survey_period_filled, :city_name, :city_id, :answered_sample, :total_sample, :answered_count, :total_count, :is_survey_completed, :cicle_one, :state_id, :all_activity, :user_activities, :state_name, :survey_period_filled

  def initialize(type, state_id, city_id, city, state, user, affiliation_id)
    db = Mongoid.default_client.database
    sc = nil
    imported_excel = nil

    if affiliation_id.present?
      schools = School.where(:affiliation_id => affiliation_id)
    elsif user.admin_state?
      schools = School.where(:affiliation_id => user.affiliation_id)
    elsif user.principal? || user.teacher?
      schools = School.find_by(:id => user.school_id)
    end

    sc = schools.pluck(:id)
    mm = schools.where(:is_school_imported => true).count()
    mnIds = schools.where(manager_id: {"$ne" => nil}).pluck(:manager_id)
    ip = Manager.where(_id: {"$in" => mnIds}, :is_principal_profile_imported => true, :type => type).count();
    sample = schools.where(:sample => true).count()
    survey_responses = SurveyResponse.where(school_id: {"$in" => sc}).count()
    total_sample = sample
    total_count = sc.count()
    answered_count = schools.where(:answered => true).count()
    answered_sample_count = schools.where(:answered => true, :sample => true).count()
    schedules = SurveySchedule.includes(:survey).where(:affiliation_id => user.affiliation_id).invese_created_order.to_a
    schedule = schedules.find{|s| s.survey.type == 'school'}
    filled = schedule.survey_end_date.nil?
    teachers = User.where(:_profile => "teacher", school_id: {"$in" => sc}).count()
    principal = User.where(:_profile => "principal", school_id: {"$in" => sc}).count()
    others = User.where(:_profile => "other", school_id: {"$in" => sc}).count()
    all_activity = nil
    user_ctivities = nil
    uaList = []

    if user.admin_state
      user_activities = UserActivity.where(:affiliation_id => user.affiliation_id)
      if !user_activities.nil?
        user_activities.each do |ua|
          uaList.push(ua.activity._id)
        end
      end
    end
    if user.admin_state
      @all_activity = Activity.where(:is_state => true).order("description asc")
    else
      @all_activity = Activity.where(:is_state => false).order("description asc")
    end
    rs = [teachers, principal, others, mm, ip, sample, survey_responses, total_sample, total_count, answered_count, answered_sample_count, filled]

    if !rs.nil?
      @teacher_profile_count =  rs[0].to_i
      @principal_profile_count = rs[1].to_i
      @other_profile_count = rs[2].to_i
      @is_school_imported = rs[3].to_i
      @is_principal_profile_imported = rs[4].to_i
      @is_sample_school_generated = rs[5].to_i
      @is_survey_completed = rs[6].to_i
      @total_sample = rs[7].to_i
      @total_count = rs[8].to_i
      @answered_count = rs[9].to_i
      @answered_sample_count =  rs[10].to_i
      @survey_id = schedule.survey_id
      @schedule_id = schedule.id
      @is_survey_period_filled = rs[11]
      @affiliation_id = user.affiliation_id
      @affiliation_name = user.affiliation_name
      if !city.nil?
        @city_name = city.name
        @city_id = city._id
        @state_name = city.state.name
        @state_id = city.state._id
      end
      if !state.nil?
        @state_name = state.name
        @state_id = state._id
      end
      @cicle_one = 0
      begin
          @cicle_one = @answered_sample_count.to_f / @total_sample
          @cicle_one = @cicle_one * 100.0

          if @cicle_one.nan?
            @cicle_one = 0
          end
      rescue ZeroDivisionError
        @cicle_one = 0
      end
      @cicle_two = 0
      begin
        @cicle_two = @answered_count.to_f / @total_count
        @cicle_two = @cicle_two * 100.0
        if @cicle_two.nan?
          @cicle_two = 0
        end
      rescue ZeroDivisionError
        @cicle_two = 0
      end
    end
    @user_activities = uaList
  end

  def self.total_of_networks(user, schools)
    if user.admin? || user.admin_state?
      networks = schools.distinct(:affiliation_id).count
    end
    return networks  
  end

  def self.amount_of_networks(user, schools)
    if user.admin? || user.admin_state?
      networks = schools.distinct(:affiliation_id).count
    end
    return networks
  end

  def self.number_of_schools_with_responses(user, schools)
    if user.admin? || user.admin_state?
      sc = schools.count()
    end
    return sc
  end

  def self.number_of_schools(user, schools)
    if user.admin? || user.admin_state?
      sc = schools.count()
    end
    return sc
  end

  def self.number_of_responses(type)
    surveys = Survey.where(:type => 'school').pluck(:_id)
    sc = get_schools_by_profile.pluck(:id)
    sr = SurveyResponse.where(school_id: {"$in" => sc}, :survey_id => {"$in" => surveys}).count()
    return sr
  end

  def self.completed_networks(type)
    user = current_user
    if user.admin_state
      group = { '$group' => { :_id => "$state_id", :count => { '$sum' => 1 } } }
    else
      group = { '$group' => { :_id => "$city_id", :count => { '$sum' => 1 } } }
    end
    match = { '$match' => { '$and' => [ {:answered => true}, {:sample => true}, {:type => type} ] } }
    answered_sample = School.collection.aggregate([match, group]).to_a
    match = { '$match' => { '$and' => [ {:answered => true}, {:type => type} ] } }
    answered_total = School.collection.aggregate([match, group]).to_a
    match = { '$match' => { '$and' => [ {:type => type} ] } }
    schools = School.collection.aggregate([match, group]).to_a
    match = { '$match' => { '$and' => [ {:sample => true}, {:type => type} ] } }
    schools_sample = School.collection.aggregate([match, group]).to_a
    ss = 0
    answered_total.each do |answered|
      schools.delete_if do |school|
        if(answered[:_id] == school[:_id])
          if( (answered[:count]/school[:count].to_f) > 0.85 )
            ss += 1
          elsif
            answered_sample.each do |answered_s|
              if answered[:_id] == answered_s[:_id]
                schools_sample.delete_if do |school_s|
                  if(answered_s[:_id] == school_s[:_id])
                    if( (answered_s[:count]/school_s[:count].to_f) > 0.85 )
                      ss += 1
                    end
                    true
                  end
                end
              end
            end
          end
          true
        end
      end
    end
    return ss
  end

  protected
    def finished(responses, total)
      return responses/total > 0.85
    end
end
