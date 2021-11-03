class Dashboard

  include Mongoid::Document

  attr_accessor :answered_sample_count, :is_school_imported, :other_profile_count, :principal_profile_count, :network_type, :teacher_profile_count, :is_principal_profile_imported, :is_sample_school_generated,:activity_checklist, :help_people_count, :is_survey_period_filled, :city_name, :city_id, :answered_sample, :total_sample, :answered_count, :total_count, :is_survey_completed

  def self.search(q)
    Dashboard.full_text_search(/.*#{q}.*/i).limit(6000)
  end

  def initialize(affiliation_id, user_id)
    db = Mongoid.default_client.database
    sc = nil
    imported_excel = nil
      sc = "var sc = db.schools.find({affiliation_id: ObjectId(\""+ affiliation_id + "\")}).map(function(scho) { return scho._id; });"
      sc+= "var mm = db.schools.find({imported_excel: true, affiliation_id: ObjectId(\""+ affiliation_id + "\")}).count();";
      sc+= "var ip = db.schools.find({imported_excel_principal: true, affiliation_id: ObjectId(\""+ affiliation_id + "\")}).count();";
      sc+= "var sample = db.schools.find({sample: true, affiliation_id: ObjectId(\""+ affiliation_id + "\")}).count();";
      sc+= "var survey_responses = db.survey_responses.find({school_id:{$in:sc}}).count();";
      sc+= "var activitiesFull = db.activities.find({ is_state: false }).map(function(act) { return act; });"
      sc+= "var activities = db.activities.find({ is_state: true }).map(function(act) { return act._id; });"
      sc+= "var total_sample = db.schools.find({affiliation_id: ObjectId(\""+ affiliation_id + "\"), sample: true}).count();";
      sc+= "var total_count = db.schools.find({affiliation_id: ObjectId(\""+ affiliation_id + "\")}).count();";
      sc+= "var answered_count = db.schools.find({affiliation_id: ObjectId(\""+ affiliation_id + "\"), answered: true}).count();";
      sc+= "var answered_sample_count = db.schools.find({affiliation_id: ObjectId(\""+ affiliation_id + "\"), answered: true, sample: true}).count();";

    sc+= "var activities_complete = db.user_activities.find({ activity_id:{$in:activities}, user_id: ObjectId(\"" + user_id + "\") }).map(function(ac) { return ac._id; });";
    sc+= "var teachers = db.users.find({_profile : \"teacher\",school_id:{$in:sc}}).count();"
    sc+= "var principal = db.users.find({_profile : \"principal\",school_id:{$in:sc}}).count();"
    sc+= "var others = db.users.find({_profile : \"others\",school_id:{$in:sc}}).count();"
    sc+= "return [teachers, principal, others, mm,ip, sample, survey_responses, total_sample, total_count, answered_count, answered_sample_count, activitiesFull, activities];"
    x = db.command({ eval: 'function(n){' + sc + '}', args: ['beskhai'], nolock: true })
    response = x.documents.to_s
    response = response.gsub('[{"retval"=>[','')
    response = response.gsub('], "ok"=>1.0}]' ,'')
    rs = response.split(" ,")


    puts "tamanho"
    p rs
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
      if !city.nil?
        @city_name = city.name
        @city_id = city._id
      end
    end
  end

  def as_json(options = { })
    city_id = nil
    city_name = nil
    state_id = nil
    state_name = nil
    if !self.city.nil?
      city_id = self.city._id
      city_name = self.city.name
    end
    if !self.state.nil?
      state_id = self.state._id
      state_name = self.state.name
    end
    { :city_id => city_id,
      :city_name => city_name,
      :network_type => self.network_type,
      :teacher_profile_count => self.teacher_profile_count,
      :other_profile_count => self.other_profile_count,
      :principal_profile_count => self.principal_profile_count,
      :school_imported => self.is_school_imported,
      :principal_profile_imported => self.is_principal_profile_imported,
      :sample_school_generated => self.is_sample_school_generated,
      :activity_checklist => self.activity_checklist,
      :survey_period => self.is_survey_period_filled,
      :survey_completed => self.is_survey_completed,
      :help_people_count => self.help_people_count,
      :state_id => state_id,
      :state_name => state_name,
      :answered_sample => self.answered_sample,
      :total_sample => self.total_sample,
      :answered_count => self.answered_count,
      :total_count => self.total_count
    }
  end

end
