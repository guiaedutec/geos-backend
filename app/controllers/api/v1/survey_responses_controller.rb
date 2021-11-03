module Api
  module V1
    class SurveyResponsesController < ApiController

      before_action :set_school, only: [:survey_response, :update, :show, :destroy]
      before_action :authenticate_user!, except: [:total_responses, :survey_example]

      def total_responses
        @surveys = Survey.all.order(:type => 1)
        list_of_survey = {}
        @surveys.each do |survey|
          if list_of_survey[survey.type].nil?
            list_of_survey[survey.type] = []
          end
          list_of_survey[survey.type].push(survey.id)
        end

        list_of_survey.each do |key, value|
          case key
          when 'personal' then list_of_survey[key] = SurveyResponse.where(:survey_id.in => value, :status => 'Complete').distinct(:user_id).count
          when 'school' then list_of_survey[key] = SurveyResponse.where(:survey_id.in => value, :status => 'Complete').distinct(:school_id).count
          else list_of_survey[key] = SurveyResponse.where(:survey_id.in => value, :status => 'Complete').count
          end
        end
        render json: list_of_survey.as_json
      end

      def survey_responses
        @lang = params[:lang]
        user = current_user
        school_id = user.school_id
        @school = School.find_by(:id => school_id)
        survey_id = params[:id]
        read_only = params[:read_only] ? true : false
        has_survey_response = params[:survey_response_id] ? true : false
        survey_response_id = params[:survey_response_id]
        @survey = Survey.find_by(:id => survey_id)

        if !has_survey_response
          @response = SurveyResponse.where(:school_id => school_id, :user_id => user.id, :survey_id => survey_id).inverse_subimitted_order.last

          if @school.type == 'Estadual'
            @schedule = SurveySchedule.where(:survey_id =>survey_id, :type => @school.type, :state_id => @school.state_id).created_order.last
          elsif
            # GEOS
            @schedule = SurveySchedule.where(:survey_id =>survey_id, :type => @school.type, :affiliation_id => @school.affiliation_id).created_order.last
          end

          if @schedule.nil?
            survey_params = Hash.new
            survey_params[:type] = @school.type
            survey_params[:state] = @school.state
            survey_params[:survey_id] = @survey.id
            survey_params[:state_id] = @school.state_id
            survey_params[:affiliation_id] = @school.affiliation_id
            if !@survey.is_cyclic
              survey_params[:recurrence_days] = @survey.recurrence_days
            end
            @schedule = SurveySchedule.new(survey_params)
            @schedule.save
            # print the errors to the development log
            Rails.logger.info(@schedule.errors.messages.inspect)
          end


          if !@survey.is_cyclic && !@response.nil? && @response.survey_schedule_id
            @schedule = SurveySchedule.find_by(:id =>@response.survey_schedule_id)
          end
        elsif
          @response = SurveyResponse.find_by(:id =>survey_response_id)
          if !@response.nil? && @response.survey_schedule_id
            @schedule = SurveySchedule.find_by(:id =>@response.survey_schedule_id)
          end
        end

        if !read_only
          if can_create_response(@response, @survey, @schedule)
            if @schedule.nil?
              @response = SurveyResponse.new(user: current_user, school_id: school_id, survey_id: Survey.find(survey_id))
            elsif
            @response = SurveyResponse.new(user: current_user, school_id: school_id, survey_id: Survey.find(survey_id), survey_schedule_id: @schedule.id)
            end
            @response.init_response
          end
        end

        if @response.nil?
          @answeres = []
        elsif
          @answeres = @response.fetch_responses
        end
        respond_to do |format|
          format.json
        end
        GC.start(immediate_sweep: true)
      end

      def can_create_response(response, survey, schedule)
        if survey.is_cyclic
          if response.nil? || response.status == 'Complete'
            if schedule.survey_start_date.nil?
              return true
            elsif DateTime.now.between?(schedule.survey_start_date, schedule.survey_end_date)
              if response.nil? || (!response.nil? && !response.submitted_at.nil? && !response.submitted_at.between?(schedule.survey_start_date, schedule.survey_end_date))
                return true
              end
            end
          end
        elsif response.nil?
          return true
        elsif response.status == 'Complete'
          if !schedule.nil?
            if schedule.recurrence_days
              if !DateTime.now.between?(response.submitted_at, response.submitted_at.next_day(schedule.recurrence_days))
                return true
              end
            elsif !DateTime.now.between?(response.submitted_at, response.submitted_at.next_day(survey.recurrence_days))
              return true
            end
          elsif !DateTime.now.between?(response.submitted_at, response.submitted_at.next_day(survey.recurrence_days))
            return true
          end
        end
        return false
      end

      def result_avg
        user = current_user
        affiliation_id = user.affiliation_id
        state_id = user.state_id;
        city_id = user.city_id;
        survey_schedule_id =  BSON::ObjectId(params[:survey_schedule_id])
        @survey = Survey.find(BSON::ObjectId(params[:survey_id]));

        #GEOS
        if user.admin_state? || user.monitor_state? || user.monitor_state_regional?
          if params[:type] == "2"
            match = { '$match' => { '$and' => [
              { :affiliation_id => affiliation_id },
              { :"results.#{survey_schedule_id}.sample" => true },
              { :"results.#{survey_schedule_id}.answered" => true },
              { :active => true },
              { :num_responses => { '$exists' => true } } ] } }
          else
            match = { '$match' => { '$and' => [
              { :affiliation_id => affiliation_id },
              { :"results.#{survey_schedule_id}.answered" => true },
              { :active => true },
              { :num_responses => { '$exists' => true } } ] } }
          end

          group = { '$group' => {
            :_id => {
            :affiliation_id => affiliation_id ,
            "type" => "$type"},
            :count => { '$sum' => 1 },
            :vision_avg => { '$avg' => "$results.#{survey_schedule_id}.vision_level" },
            :competence_avg => { '$avg' => "$results.#{survey_schedule_id}.competence_level" },
            :crd_avg => { '$avg' => "$results.#{survey_schedule_id}.resource_level" },
            :infra_avg => { '$avg' => "$results.#{survey_schedule_id}.infrastructure_level" } } }
        end

        project = { '$project' => {
          :_id => false,
          :state => "$_id.state",
          :state_name => "$_id.state_name",
          :city => "$_id.city",
          :city_name => "$_id.city_name",
          :type => "$_id.type",
          :count => true,
          :vision_avg => true,
          :competence_avg => true,
          :crd_avg => true,
          :infra_avg => true } }

        if params[:regional]
          match["$match"]["$and"].push( {:regional => params[:regional] } )
        end

        @response = School.collection.aggregate([match, group, project])

        render json: @response.as_json
        @response = nil
        GC.start(immediate_sweep: true)
      end

      def result_per_dimension
        user = current_user
        # GEOS
        affiliation_id = user.affiliation_id
        affiliation_name = user.affiliation_name

        survey_id =  BSON::ObjectId(params[:survey_id])
        @survey_schedule_id =  BSON::ObjectId(params[:survey_schedule_id])
        @survey = Survey.find(survey_id);
        # GEOS
        if user.admin_state? || user.admin_city? || user.monitor_state? || user.monitor_state_regional?
          if params[:type] == "2"
            match = { '$match' => { '$and' => [
              { :affiliation_id => affiliation_id },
              { :"results.#{@survey_schedule_id}.sample" => true },
              { :"results.#{@survey_schedule_id}.answered" => true },
              { :active => true } ] } }
          else
            match = { '$match' => { '$and' => [
              { :affiliation_id => affiliation_id },
              { :"results.#{@survey_schedule_id}.answered" => true },
              { :active => true } ] } }
          end
        end
        
        lookup1 = { '$lookup' => {
          :from => "survey_responses",
          :localField => "_id",
          :foreignField => "school_id",
          'as' => "survey_responses"} }
        unwind = { '$unwind' => "$survey_responses" }
        match2 = { '$match' => { '$and' => [
          { :survey_responses => { '$ne' => [] } },
          { "survey_responses.survey_id" => survey_id },
          { "survey_responses.survey_schedule_id" => @survey_schedule_id },
          { "survey_responses.in_use" => true } ] } }
        project1 = { '$project' => {
#          :inep_code => true,
          :vision_level => true,
          :competence_level => true,
          :resource_level => true,
          :infrastructure_level => true,
          :survey_responses => true } }
        if @survey.has_combined
          match2["$match"]["$and"].push({ "survey_responses.type" => 'Combined' })
        end
        if params[:regional]
          matchR = { '$match' => { :regional => params[:regional] } }
          @response = School.collection.aggregate([match, matchR, lookup1, unwind, match2, project1])
        else
          @response = School.collection.aggregate([match, lookup1, unwind, match2, project1])
        end
        results = []
        results[0] = [0,0,0,0]
        results[1] = [0,0,0,0]
        results[2] = [0,0,0,0]
        results[3] = [0,0,0,0]
        totals = 0;

        @response.each do |school|
          totals += 1

          school['survey_responses']["results"].each do |key|
            if key['name'] === "Visão"
              if key['value'].to_i == 1
                results[0][0] += 1
              elsif key['value'].to_i == 2
                results[0][1] += 1
              elsif key['value'].to_i == 3
                results[0][2] += 1
              elsif key['value'].to_i == 4
                results[0][3] += 1
              end
            end
            if key['name'] === "Competência"
              if key['value'].to_i == 1
                results[1][0] += 1
              elsif key['value'].to_i == 2
                results[1][1] += 1
              elsif key['value'].to_i == 3
                results[1][2] += 1
              elsif key['value'].to_i == 4
                results[1][3] += 1
              end
            end
            if key['name'] === "Recursos"
              if key['value'].to_i == 1
                results[2][0] += 1
              elsif key['value'].to_i == 2
                results[2][1] += 1
              elsif key['value'].to_i == 3
                results[2][2] += 1
              elsif key['value'].to_i == 4
                results[2][3] += 1
              end
            end
            if key['name'] === "Infraestrutura"
              if key['value'].to_i == 1
                results[3][0] += 1
              elsif key['value'].to_i == 2
                results[3][1] += 1
              elsif key['value'].to_i == 3
                results[3][2] += 1
              elsif key['value'].to_i == 4
                results[3][3] += 1
              end
            end
          end
        end
        if(totals > 0)
          results[0][0] = 100 * results[0][0] / totals
          results[0][1] = 100 * results[0][1] / totals
          results[0][2] = 100 * results[0][2] / totals
          results[0][3] = 100 * results[0][3] / totals
          results[1][0] = 100 * results[1][0] / totals
          results[1][1] = 100 * results[1][1] / totals
          results[1][2] = 100 * results[1][2] / totals
          results[1][3] = 100 * results[1][3] / totals
          results[2][0] = 100 * results[2][0] / totals
          results[2][1] = 100 * results[2][1] / totals
          results[2][2] = 100 * results[2][2] / totals
          results[2][3] = 100 * results[2][3] / totals
          results[3][0] = 100 * results[3][0] / totals
          results[3][1] = 100 * results[3][1] / totals
          results[3][2] = 100 * results[3][2] / totals
          results[3][3] = 100 * results[3][3] / totals
        end

        a = results.map{ |s| {level1: s[0], level2: s[1], level3: s[2], level4: s[3]} }
        render json: a.as_json
        a = nil
        GC.start(immediate_sweep: true)
      end

      # GEOS
      def result_questions_per_dimension
        user = current_user

        affiliation_id = user.affiliation_id
        affiliation_name = user.affiliation_name
        survey_id =  BSON::ObjectId(params[:survey_id])
        @survey_schedule_id =  BSON::ObjectId(params[:survey_schedule_id])
        @survey = Survey.find(survey_id);

        start = Time.now

        if user.admin_state? || user.monitor_state? || user.monitor_state_regional?
          if params[:type] == "2"
            match = { '$match' => { '$and' => [
              { :affiliation_id => affiliation_id },
              { :affiliation_name => affiliation_name },
              { :"results.#{@survey_schedule_id}.sample" => true },
              { :"results.#{@survey_schedule_id}.answered" => true },
              { :active => true } ] } }
          else
            match = { '$match' => { '$and' => [
              { :affiliation_id => affiliation_id },
              { :affiliation_name => affiliation_name },
              { :"results.#{@survey_schedule_id}.answered" => true },
              { :active => true } ] } }
          end
        end
        lookup1 = { '$lookup' => {
        :from => "survey_responses",
        :localField => "_id",
        :foreignField => "school_id",
        'as' => "survey_responses"} }
        unwind1 = { '$unwind' => "$survey_responses" }
        match1 = { '$match' => { '$and' => [
          { "survey_responses.survey_id" => survey_id },
          { "survey_responses.survey_schedule_id" => @survey_schedule_id },
          { "survey_responses.type" => { '$exists' => false} },
          { "survey_responses.in_use" => true } ] } }
        lookup2 = { '$lookup' => {
          :from => "response_answeres",
          :localField => "survey_responses._id",
          :foreignField => "survey_response_id",
          'as' => "responses"} }
        match2 = { '$match' => { '$and' => [
          { :responses => { '$ne' => [] } },
          { "responses.options" => { '$ne' => [] } } ] } }
        unwind2 = { '$unwind' => "$responses" }
        project1 = { '$project' => {
          :_id => "$responses.survey_question_id",
          :content => {
            :student_diurnal_count => "$student_diurnal_count",
            :student_vespertine_count => "$student_vespertine_count",
            :student_nocturnal_count => "$student_nocturnal_count",
            :student_full_count => "$student_full_count",
            :user_id => "$responses.user_id",
            :school_id => "$responses.school_id",
            # :survey_id => "$survey_responses.survey_id",
            :response_id => "$survey_responses._id",
            :options => "$responses.options" },
          :in_use => "$survey_responses.in_use" } }

        group = { '$group' => {
          :_id => "$_id",
          :count => { '$sum' => 1 },
          :content => {'$addToSet' => "$content"} } }
        sort = { '$sort' => { "_id" => 1 } }
        if params[:regional]
          matchR = { '$match' => { :regional => params[:regional] } }
          response_array = School.collection.aggregate([match, matchR, lookup1, unwind1, match1, lookup2, match2, unwind2, project1, group, sort]).to_a
        else
          response_array = School.collection.aggregate([match, lookup1, unwind1, match1, lookup2, match2, unwind2, project1, group, sort]).to_a
        end

        results_questions = Array.new { Array.new };
        results_questions_pc = Array.new { Array.new };

        # puts(Time.now - start);
        questionsDetails = Array.new
        if response_array.any?
          questions = nil
          if(current_user.admin_state? || current_user.monitor_state?  || current_user.monitor_state_regional?)
            type_role = "Estadual"
            questions = SurveyQuestion.any_of({:affiliation => affiliation_id.to_s}, {:page => { '$in' => [3,4,5,6] } }).order(:page => 1, :name => 1)
          end
          # puts(Time.now - start);

          questions.each do |question|
            question_results = Array.new
            if question.type == 'pc' && question.weight > 0
              questions_add_ons = questions.select { |q| q.survey_id == survey_id && q.compound == true && q.compound_ref == question.compound_ref && !q.compound_first }
              questions_infra_D = []
              response_array.delete_if do |survey_response|
                if survey_response["_id"] == question.id
                  question_results = survey_response["content"]
                  question_results.sort_by! {|obj| obj["response_id"]}
                  true
                elsif questions_add_ons.any?{|a| a[:_id] == survey_response["_id"]}
                  qTemp = survey_response["content"]
                  qTemp.sort_by! {|obj| obj["response_id"]}
                  questions_infra_D.concat(qTemp)
                  true
                end
              end

              question_results.each do |survey_response|
                questions_infra_D.delete_if do |q|
                  if survey_response["response_id"] == q["response_id"]
                    survey_response["options"][0] = survey_response["options"][0].to_i + q["options"][0].to_i
                    true
                  end
                end
              end
            else
              response_array.delete_if do |survey_response|
                if(survey_response["_id"] == question.id)
                  question_results = survey_response["content"]
                  true
                end
              end
            end

            questionDetail  = {}
            questionDetail["page"] = question.page
            questionDetail["question"] = question.name
            questionDetail["question_id"] = question.id
            options = Array.new
            question.survey_question_description.each do |value|
              option  = {}
              option["option"] = value["id"]
              option["count"] = 0
              option["option_text"] = value["value"]
              options.push(option)
            end

            if question_results.any? && !question.survey_section.nil? && question.weight >= 0
              local = [question.name.split(' - ').first,0,0,0,0, question.page]
              # puts question.name;
              if(question.type != 'pc')
                question_results.each do |qr|
                  qvalue = calc_score(question, qr["options"])
                  case (qvalue*question.normalise_score_ratio).round
                  when 0
                    local[1] += 1
                  when 1
                    local[2] += 1
                  when 2
                    local[3] += 1
                  when 3
                    local[4] += 1
                  end
                  qr["options"].each do |value|
                    if options.any?
                      result = options.select{ |opt| opt["option"].to_s == value }
                      if result.any?
                        result[0]["count"] += 1
                      end
                    end
                  end
                end
                questionDetail["result"] = options
              else
                if question.weight > 0
                  localpc = [question.name.split(' - ').first+"$PC",0,0,0,0,0,0, question.page]
                  question_results.each do |qr|
                    max_shift_students = [qr["student_diurnal_count"], qr["student_vespertine_count"], qr["student_nocturnal_count"], qr["student_full_count"]].map(&:to_i).max
                    qvalue = students_per_computer_score(max_shift_students, qr["options"][0])
                    # puts "length #{question_results.length} | question._id #{question._id} | qr #{qr["options"][0]} | qvalue #{qvalue}";
                    if qvalue * question.weight < 1.02
                      qvalue = qvalue * question.weight
                    end
                    case qvalue
                    when 0.17
                      localpc[1] += 1
                      local[1] +=1
                    when 0.34
                      localpc[2] += 1
                      local[2] +=1
                    when 0.51
                      localpc[3] += 1
                      local[2] +=1
                    when 0.68
                      localpc[4] += 1
                      local[3] +=1
                    when 0.85
                      localpc[5] += 1
                      local[3] +=1
                    when 1.02
                      localpc[6] += 1
                      local[4] +=1
                    end
                  end
                end
                localpc[1] = 100*localpc[1] / question_results.length
                localpc[2] = 100*localpc[2] / question_results.length
                localpc[3] = 100*localpc[3] / question_results.length
                localpc[4] = 100*localpc[4] / question_results.length
                localpc[5] = 100*localpc[5] / question_results.length
                localpc[6] = 100*localpc[6] / question_results.length
                results_questions_pc.push(localpc)
              end
              if  question.weight > 0
                local[1] = 100*local[1] / question_results.length
                local[2] = 100*local[2] / question_results.length
                local[3] = 100*local[3] / question_results.length
                local[4] = 100*local[4] / question_results.length
                results_questions.push(local)
              end
            end
            questionsDetails.push(questionDetail)
            # puts "#{Time.now - start} - fim";
          end
        end

        # puts(Time.now - start);
        r = results_questions.map{ |s| {name: s[0], level1: s[1], level2: s[2], level3: s[3], level4: s[4], page: s[5]} }
        r.push( results_questions_pc.map{ |s| {name: s[0], level1: s[1], level2: s[2], level3: s[3], level4: s[4], level5: s[5], level6: s[6], page: s[7], type: 'pc'} } )
        r.push( questionsDetails )
        render json: r.as_json
        puts "#{Time.now - start} - TIME: Result question per dimension";
        r = nil
        GC.start(immediate_sweep: true)
      end

      def responses_statistics
        user = current_user
        state_id = user.state_id;
        city_id = user.city_id;

        if(params[:network] === "Estadual")
          state_id = BSON::ObjectId(params[:state_id])
        end

        if(params[:network] === "Municipal")
          city_id = params[:city_id].to_s
          city_id = BSON::ObjectId.from_string( params[:city_id] )
        end

        if user.admin_state? || user.monitor_state? || user.monitor_state_regional? || params[:network] === "Estadual"
          match1 = { '$match' => {
            '$and' => [
              { :page => { '$in' => [3,4,5,6,7] } }, {
              '$or' => [
                {:type_role => nil }, {
                '$and' => [
                  { :type_role => "Estadual"},
                  { :state => state_id } ] } ] } ] } }
          project3 = { '$project' => {
            :_id => true,
            :name => true,
            :page => true,
            :question_description_value => true,
            :school_id => true,
            :user_id => true,
            :question_description_id => true,
            :response_option =>true,
            :school => { '$filter' => {
              'input' => "$school",
              'as' => "school",
              'cond' => { '$eq' => [ "$$school.state_id",state_id ] } } } } }
        else
          if user.admin_city? ||  user.monitor_city? || user.monitor_city_regional? || params[:network] === "Municipal"
            match1 = { '$match' => {
              '$and' => [
                { :page => { '$in' => [3,4,5,6,7] } }, {
                '$or' => [
                  {:type_role => nil }, {
                  '$and' => [
                    { :type_role => "Municipal"},
                    { :city => city_id } ] } ] } ] } }
            project3 = { '$project' => {
              :_id => true,
              :name => true,
              :page => true,
              :question_description_value => true,
              :school_id => true,
              :user_id => true,
              :question_description_id => true,
              :response_option =>true,
              :school => { '$filter' => {
                'input' => "$school",
                'as' => "school",
                'cond' => { '$eq' => [ "$$school.city_id",city_id ] } } } } }
          end
        end

        lookup1 = { '$lookup' => {
          :from => "response_answeres",
          :localField => "_id",
          :foreignField => "survey_question_id", 'as' => "responses" } }
        unwind1 = { '$unwind' => "$survey_question_description" }
        unwind2 = { '$unwind' => "$responses" }
        unwind3 = { '$unwind' => "$responses.options" }
        project1 = { '$project' => {
          :name => true,
          :page => true,
          :question_description_value => "$survey_question_description.value",
          :school_id => "$responses.school_id",
          :user_id => "$responses.user_id",
          :question_description_id => { '$substr' => [ "$survey_question_description.id",   0, 8] },
          :responses_options => "$responses.options" } }
        project2 = { '$project' => {
          :name => true,
          :page => true,
          :question_description_value => true,
          :school_id => true,
          :user_id => true,
          :question_description_id => true,
          :responses_options => true,
          :eq_response => { '$eq' => ["$question_description_id", "$responses_options"] } } }
        match2 = { '$match' => { :eq_response => true} }
        lookup2 = { '$lookup' => {
          :from => "schools",
          :localField => "school_id",
          :foreignField => "_id",
          'as' => "school" } }

        if params[:regional]
          match3 = { '$match' => { '$and' => [
            { :school => { '$ne' => [] } },
            { "school.answered" => true },
            { "school.regional" => params[:regional] } ] } }
        else
          match3 = { '$match' => { '$and' => [
            { :school => { '$ne' => [] } },
            { "school.answered" => true } ] } }
        end
        # match4 = { '$match' => { "school" => { '$ne' => [] } } }
        lookup3 = { '$lookup' => {
          :from => "survey_responses",
          :localField => "school_id",
          :foreignField => "school_id",
          'as' => "survey" } }
        unwind4 = { '$unwind' => "$school" }
        unwind5 = { '$unwind' => "$survey" }
        project4 = { '$project' => {
          :_id => true,
          :name => true,
          :page => true,
          :question_description_value => true,
          :school_id => true,
          :user_id => true,
          :question_description_id => true,
          :response_option => true,
          :school => true,
          :survey => true,
          :valid => { '$eq' => ['$survey.user_id','$user_id']}
        } }
        match5 = { '$match' => { "valid" => true } }
        match6 = { '$match' => { "survey.in_use" => true } }
        group1 = { '$group' => {
          :_id => {
            :page => "$page",
            :name => "$name",
            :question_id => "$_id",
            :option=> "$question_description_id",
            :question_description_value => "$question_description_value" },
          :count => { '$sum' => 1 } } }
        group2 = { '$group' => {
          :_id => {
            "page" => "$_id.page",
            "name" => "$_id.name",
            "question_id" => "$_id.question_id" },
          "result" => { "$push" => {
            "option"=> "$_id.option",
            "option_text" => "$_id.question_description_value",
            "count" => "$count" } } } }
        sort = { '$sort' => { :_id => 1 } }
        project5 = {  '$project' => {
          :_id => false,
          :question_id => "$_id.question_id",
          :page => "$_id.page",
          :question => "$_id.name",
          :result => "$result" } }

        @response = SurveyQuestion.collection.aggregate([match1, lookup1, unwind1, unwind2, unwind3, project1, project2, match2, lookup2, match3, project3, lookup3, unwind4, unwind5, project4, match5, match6, group1, group2, sort, project5])
        render json: @response.as_json
        @response = nil
        GC.start(immediate_sweep: true)
      end

      def responses_details
        user = current_user
        state_id = user.state_id;
        city_id = user.city_id;

        if(params[:network] === "Estadual")
          state_id = BSON::ObjectId(params[:state_id])
        end

        if(params[:network] === "Municipal")
          city_id = params[:city_id].to_s
          city_id = BSON::ObjectId.from_string( params[:city_id] )
        end

        if user.admin_state? || user.monitor_state? || user.monitor_state_regional? || params[:network] === "Estadual"
          match1 = { '$match' => {
            '$and' => [
              { :type => "Estadual"},
              { :state_id => state_id } ] } }
        else
          if user.admin_city? ||  user.monitor_city? || user.monitor_city_regional? || params[:network] === "Municipal"
            match1 = { '$match' => {
              '$and' => [
                { :type => "Municipal"},
                { :city_id => city_id } ] } }
          end
        end
        lookup1 = { '$lookup' => {
          :from => "survey_responses",
          :localField => "_id",
          :foreignField => "school_id",
          'as' => "survey_responses"} }
        match2 = { '$match' => { '$and' => [ { "survey_responses" => { '$ne' => [] } }, { "survey_responses.in_use" => true } ] } }
        project1 = { '$project' => {
          :inep_code => true,
          :name => true,
          :page => true,
          :student_diurnal_count => true,
          :student_vespertine_count => true,
          :student_nocturnal_count => true,
          :student_full_count => true,
          :vision_level => true,
          :competence_level => true,
          :resource_level => true,
          :infrastructure_level => true,
          :survey_responses => {
            :user_id => true } } }
        lookup2 = { '$lookup' => {
          :from => "response_answeres",
          :localField => "survey_responses.user_id",
          :foreignField => "user_id",
          'as' => "responses" }  }
        @response = School.collection.aggregate([match1, lookup1, match2, project1, lookup2])
        render json: @response.as_json
        @response = nil
        GC.start(immediate_sweep: true)
      end

      def respond_answers
        
        if current_user.other?
          #other - no to register
          respond_to do |format|
            format.json {
              render :json => {:valid => true }.to_json, :status => 200
            }
          end
        else
          survey_id =  BSON::ObjectId.from_string(params[:id_survey])
          response_id = BSON::ObjectId.from_string(params[:id_response])

          # response return false by default
          flow_success = false

          # get all responses of user
          responses = params[:responses]

          # response is required, otherwise break flow
          if !responses.nil? && responses.present? 

            last_option_key = nil
            options = {}
            responses.each do |key, value|
              # questionsTotal.push(get_string_between(key,'[',']'))
              options[key] = value
              last_option_key = key
            end

            user_id = current_user.id
            school_id = current_user.school_id

            # get all response to alternative question updated by user in form
            @questionEdit = ResponseAnswer.where(:user_id => user_id, :survey_response_id => response_id, survey_question_id: {"$in" => options.keys})

            # if response database exist into database. Only update 'options' response
            if @questionEdit.count > 0

              @questionEdit.each do |q|

                # get option values by 'survey_question_id' key and
                options_response = build_options(options.fetch(q.survey_question_id.to_s))

                # only update collection
                q.update_attributes(
                  school_id: school_id,
                  user_id: user_id,
                  survey_response_id: response_id,
                  options: options_response
                )

                # remove 'survey_question_id' from hash
                options.delete(q.survey_question_id.to_s)
              end
            end

            # verify if exist element into options response hash
            unless options.empty?
              options.each do |key, value|
                options_response = build_options(value)
                @sa = ResponseAnswer.new
                @sa.school_id = school_id
                @sa.user_id = user_id
                @sa.survey_response_id = response_id
                @sa.options = options_response
                @sa.survey_question_id = key
                @sa.save!
              end
            end
            flow_success = true
          end

          respond_to do |format|
            format.json {
              render :json => {:valid => flow_success }.to_json, :status => 200
            }
          end
        end
      end

      def indicators_table
        @schools = School.where(:used_indicator => true, :vision_level.exists => true, :competence_level.exists => true, :resource_level.exists => true, :infrastructure_level.exists => true)
        results = Hash.new;
        results['vision'] = [0.0,0.0,0.0,0.0]
        results['competence'] = [0.0,0.0,0.0,0.0]
        results['resource'] = [0.0,0.0,0.0,0.0]
        results['infra'] = [0.0,0.0,0.0,0.0]
        percent = 1.0/@schools.count
        @schools.each do |school|
          results['vision'][school.vision_level-1] += percent
          results['competence'][school.competence_level-1] += percent
          results['resource'][school.resource_level-1] += percent
          results['infra'][school.infrastructure_level-1] += percent
        end
        total_results = Hash.new
        total_results["geral"] = results

        @schools = School.where(:type => 'Estadual',:used_indicator => true, :vision_level.exists => true, :competence_level.exists => true, :resource_level.exists => true, :infrastructure_level.exists => true)
        results = Hash.new;
        results['vision'] = [0.0,0.0,0.0,0.0]
        results['competence'] = [0.0,0.0,0.0,0.0]
        results['resource'] = [0.0,0.0,0.0,0.0]
        results['infra'] = [0.0,0.0,0.0,0.0]
        percent = 1.0/@schools.count
        @schools.each do |school|
          results['vision'][school.vision_level-1] += percent
          results['competence'][school.competence_level-1] += percent
          results['resource'][school.resource_level-1] += percent
          results['infra'][school.infrastructure_level-1] += percent
        end
        total_results["estadual"] = results

        @schools = School.where(:type => 'Municipal',:used_indicator => true, :vision_level.exists => true, :competence_level.exists => true, :resource_level.exists => true, :infrastructure_level.exists => true)
        results = Hash.new;
        results['vision'] = [0.0,0.0,0.0,0.0]
        results['competence'] = [0.0,0.0,0.0,0.0]
        results['resource'] = [0.0,0.0,0.0,0.0]
        results['infra'] = [0.0,0.0,0.0,0.0]
        percent = 1.0/@schools.count
        @schools.each do |school|
          results['vision'][school.vision_level-1] += percent
          results['competence'][school.competence_level-1] += percent
          results['resource'][school.resource_level-1] += percent
          results['infra'][school.infrastructure_level-1] += percent
        end
        total_results["municipal"] = results

        render json: total_results.as_json
      end

      def indicators_details
        school_ids = School.where(:used_indicator => true, :vision_level.exists => true, :competence_level.exists => true, :resource_level.exists => true, :infrastructure_level.exists => true).pluck(:_id).uniq
        @response = SurveyResponse.where(:school.in => school_ids, :in_use => true ).page(params["page"]).per(params["size"])

        result = Array.new
        @response.each do |resp|
          # value["response"] = resp
          value = Hash.new
          #GEOS
          value["affiliation_name"] = resp.school.affiliation_name
          value["level_1_name"] = resp.school.level_1_name
          value["level_2_name"] = resp.school.level_2_name
          value["level_3_name"] = resp.school.level_3_name
          value["level_4_name"] = resp.school.level_4_name
          value["school_type"] = resp.school.type          
          value["school_inep"] = resp.school.inep_code
          value["school_name"] = resp.school.name
          value["vision_level"] = resp.vision_level
          value["competence_level"] = resp.competence_level
          value["resource_level"] = resp.resource_level
          value["infrastructure_level"] = resp.infrastructure_level
          value["result"] = resp.calculate_score_not_ceil(resp)

          #Antes
          # value["estate_name"] = resp.school.state_name
          # value["city_name"] = resp.school.city_name
          # value["school_type"] = resp.school.type
          # value["school_inep"] = resp.school.inep_code
          # value["school_name"] = resp.school.name
          # value["vision_level"] = resp.vision_level
          # value["competence_level"] = resp.competence_level
          # value["resource_level"] = resp.resource_level
          # value["infrastructure_level"] = resp.infrastructure_level
          # value["result"] = resp.calculate_score_not_ceil(resp)
          result.push(value)
        end

        render json: result.as_json

      end

      def get_string_between(any_string, start_at, end_at)
        any_string = " #{any_string}"
        ini = any_string.index(start_at)
        return any_string if ini == 0
        ini += start_at.length
        length = any_string.index(end_at, ini).to_i - ini
        any_string[ini,length]
      end

      def build_options(options_response)
        arr = []
        if options_response.instance_of? String
          hash = {}
          arr.push(hash[options_response] = options_response)
        else
          options_response.each do |e|
            hash = {}
            hash[e] = e
            arr.push(hash)
          end
        end
      end

      def calc_score(question, options)
        #metodo responsavel por gerar a pontuacao para a pergunta relacionada (survey_question_id)
        #qualquer mudanca nas regras de pontuacao devem ser refletidas neste metodo
        scor = 0
        if (question.type == 'radio')
          #calculo para questoes tipo radio
          opt =  Integer(options[0])
          if !question.survey_question_description.nil?
            question.survey_question_description.each_with_index do |sqd, index|
              value = sqd["id"].to_i
              if value === opt
                scor = sqd["weight"]
              end
            end
          end
          scor * question.weight
        elsif (question.type == 'checkbox' || question.type == 'table')
          #calculo para questoes tipo checkbox
          if !question.survey_question_description.nil?
            question.survey_question_description.each_with_index do |sqd, index|
              value = sqd["id"].to_i
              options.each do |opt|
                if(Integer(opt) == value)
                  scor = scor + sqd["weight"]
                end
              end
            end
          end
          scor = scor * question.weight
          if scor > question.weight
            question.weight
          else
            scor
          end
        end
      end

      def students_per_computer_score(max_shift_students, computers)
        case max_shift_students / (computers.to_f || 1.0)
        when 0...2.5 then 1.02
        when 2.5...8.5 then 0.85
        when 8.5...16.5 then 0.68
        when 16.5...30.5 then 0.51
        when 30.5...50 then 0.34
        else 0.17
        end
      end

      def all_responses
        survey_id = params[:id_survey]
        @survey_responses = SurveyResponse.includes(:school).where(:survey_id => survey_id, :status => 'Complete')
        @survey_responses = @survey_responses.sort_by{ |r| [r.school.state.name, r.school.type, r.school.city.name, r.user.name] }
        render json: @survey_responses.as_json(:include => [:school, :user])
      end

      def distribution_by_area
        pipeline = Array.new
        survey_id = params[:survey_id]
        user = current_user
        dateStart = params[:start].to_s != "" ? params[:start].to_datetime : -12.month.from_now
        dateEnd = params[:end].to_s != "" ? (params[:end]+"T23:59:59").to_datetime : 1.day.from_now

        matchSurveyResponses = {
          "$match" => {
            "$and" => [
              { "submitted_at" => { "$gte" => dateStart, "$lte" => dateEnd } },
              { "survey_id"=> BSON::ObjectId(survey_id) },
              { "status"=> "Complete" }
            ]
          }
        }
        pipeline.push(matchSurveyResponses)

        if !user.super_admin? || (params[:used_indicator] && params[:used_indicator].to_s != "")
          used_indicator = {}

          if params[:used_indicator].to_s == "true"
            used_indicator = { "school.used_indicator" => true }
          elsif params[:used_indicator].to_s == "false"
            used_indicator = { "$or" => [ { "school.used_indicator" => { "$exists" => false } }, { "school.used_indicator" => false } ] }
          end

          lookupSchool = {
            "$lookup" => {
              :from => "schools",
              :localField => "school_id",
              :foreignField => "_id",
              :as => "school"
            }
          }
          matchFilterSchool = {
            "$match" => {
              "$and" => [ used_indicator ].concat(match_filter_global)
            }
          }
          pipeline.push(lookupSchool, matchFilterSchool)
        end

        if (params[:knowledge] && params[:knowledge].to_s != "") || (params[:teaching_stage] && params[:teaching_stage].to_s != "")
          lookupUser = {
            "$lookup" => {
              :from => "users",
              :localField => "user_id",
              :foreignField => "_id",
              :as => "user"
            }
          }
          matchFilterUser = {
            "$match" => {
              "$and" => match_filter_user
            }
          }
          pipeline.push(lookupUser, matchFilterUser)
        end

        projectResults = {
          "$project" => {
            :_id => 1,
            :results => 1
          }
        }
        unwindResults = { "$unwind" => "$results" }
        sortResults = {
          "$sort" => {
            "_id" => 1,
            "results.value" => 1
          }
        }
        groupSplitAreaName = {
          "$group" => {
            :_id => {
              "_id": "$_id",
              "area_name": { "$arrayElemAt" => [ { "$split" => %w($results.name </H1>) }, 0 ] }
            },
            :count => { "$sum" => 1 },
            :results => { "$push" => "$results.value" }
          }
        }
        projectMidpoint = {
          "$project" => {
            :id => 1,
            :results => 1,
            :midpoint => {
              "$divide" => [ { "$sum" => [ "$count", -1 ] }, 2 ]
            }
          }
        }
        projectHighLow = {
          "$project" => {
            :id => 1,
            :results => 1,
            :high => { "$ceil" => "$midpoint" },
            :low => { "$floor" => "$midpoint" }
          }
        }
        projectMedian = {
          "$project" => {
            :id => 1,
            :results => 1,
            :median => { "$avg" => [ { "$arrayElemAt" => [ "$results", "$high" ] }, { "$arrayElemAt" => [ "$results", "$low" ] } ] }
          }
        }
        groupAreas = {
          "$group" => {
            :_id => {
              "area": "$_id.area_name",
              "median": { "$ceil" => "$median" }
            },
            :count => { "$sum" => 1 }
          }
        }
        projectMain = {
          "$project" => {
            :_id => false,
            :area => { "$substr": [ "$_id.area", 4, { "$strLenCP": "$_id.area" } ] },
            :level => "$_id.median",
            :count => "$count"
          }
        }
        sortMain = { "$sort" => { "area" => 1, "level" => 1 } }
        pipeline.push(projectResults, unwindResults, sortResults, groupSplitAreaName, projectMidpoint, projectHighLow, projectMedian, groupAreas, projectMain, sortMain)

        survey_responses = SurveyResponse.collection.aggregate(pipeline, :allow_disk_use => true, :read => { :mode => :secondary_preferred }).to_a

        @responseGroup = Hash.new
        survey_responses.each do |resp|
          if !@responseGroup[resp[:area]]
            @responseGroup[resp[:area]] = {}
          end

          level = resp[:level].round
          if !@responseGroup[resp[:area]][level]
            @responseGroup[resp[:area]][level] = {}
          end

          @responseGroup[resp[:area]][level] = resp[:count]
        end

        render json: (@responseGroup).as_json()
      end

      def result_self_evaluation_details
        @lang = params[:lang]
        pipeline = Array.new
        survey_id = params[:survey_id]
        user = current_user
        dateStart = params[:start].to_s != "" ? params[:start].to_datetime : -12.month.from_now
        dateEnd = params[:end].to_s != "" ? (params[:end]+"T23:59:59-03:00").to_datetime : Time.now

        matchSurveyResponses = {
          "$match" => {
            "$and" => [
              { "submitted_at" => { "$gte" => dateStart, "$lte" => dateEnd } },
              { "survey_id"=> BSON::ObjectId(survey_id) },
              { "status"=> "Complete" }
            ]
          }
        }
        pipeline.push(matchSurveyResponses)

        if !user.super_admin? || (params[:used_indicator] && params[:used_indicator].to_s != "")
          used_indicator = {}
          isRegional = {}

          if params[:used_indicator].to_s == "true"
            used_indicator = { "school.used_indicator" => true }
          elsif params[:used_indicator].to_s == "false"
            used_indicator = { "$or" => [ { "school.used_indicator" => { "$exists" => false } }, { "school.used_indicator" => false } ] }
          end

          if params[:level] && (params[:level].to_s == 'pais' || params[:level].to_s == 'estado')
            used_indicator = {}
          end

          if params[:regional] && params[:regional].to_s != ""
            isRegional = { "school.regional" => params[:regional] }
          end

          lookupSchool = {
            "$lookup" => {
              :from => "schools",
              :localField => "school_id",
              :foreignField => "_id",
              :as => "school"
            }
          }
          matchFilterSchool = {
            "$match" => {
              "$and" => [ isRegional, used_indicator ].concat(match_filter_global)
            }
          }
          pipeline.push(lookupSchool, matchFilterSchool)
        end

        if (params[:knowledge] && params[:knowledge].to_s != "") || (params[:teaching_stage] && params[:teaching_stage].to_s != "")
          lookupUser = {
            "$lookup" => {
              :from => "users",
              :localField => "user_id",
              :foreignField => "_id",
              :as => "user"
            }
          }
          matchFilterUser = {
            "$match" => {
              "$and" => match_filter_user
            }
          }
          pipeline.push(lookupUser, matchFilterUser)
        end

        projectResults = {
          "$project" => {
            :_id => 1,
            :results => 1
          }
        }
        unwindResults = { "$unwind" => "$results" }
        groupMain = {
          "$group" => {
            :_id => {
              :name => "$results.name",
              :value => "$results.value"
            },
            :count => { "$sum" => 1 }
          }
        }
        pipeline.push(projectResults, unwindResults, groupMain)
        survey_responses = SurveyResponse.collection.aggregate(pipeline, :allow_disk_use => true, :read => { :mode => :secondary_preferred }).to_a

        @responseGroup = Hash.new
        survey_responses.each do |resp|
          if !@responseGroup[resp[:_id][:name]]
            @responseGroup[resp[:_id][:name]] = {}
          end

          if !@responseGroup[resp[:_id][:name]][resp[:_id][:value]]
            @responseGroup[resp[:_id][:name]][resp[:_id][:value]] = {}
          end

          @responseGroup[resp[:_id][:name]][resp[:_id][:value]] = resp[:count]
        end
        @response = @responseGroup

        render json: @response.as_json
      end

      def responses_self_evaluation_demography
        pipeline = Array.new
        survey_id = params[:survey_id]
        dateStart = params[:start].to_s != "" ? params[:start].to_datetime : -12.month.from_now
        dateEnd = params[:end].to_s != "" ? (params[:end]+"T23:59:59-03:00").to_datetime : Time.now
        used_indicator = {}
        used_indicator_staff = {}
        statesIds = []
        citiesIds = []

        matchSurveyResponses = {
          '$match' => {
            '$and' => [
              { "submitted_at" => { '$gte' => dateStart, '$lte' => dateEnd } },
              { "survey_id"=> BSON::ObjectId(survey_id) },
              { "status"=> "Complete" }
            ]
          }
        }
        pipeline.push(matchSurveyResponses)

        lookupSchoolSurveyResponses = {
          '$lookup' => {
            :from => "schools",
            :localField => "school_id",
            :foreignField => "_id",
            :as => "school"
          }
        }
        unwindSchool = { '$unwind' => "$school" }
        pipeline.push(lookupSchoolSurveyResponses, unwindSchool)

        if params[:used_indicator] && params[:used_indicator].to_s != ""
          if params[:used_indicator].to_s == "true"
            used_indicator = { "school.used_indicator" => true }
            used_indicator_staff = { "used_indicator" => true }
          elsif params[:used_indicator].to_s == "false"
            used_indicator = { "$or" => [ { "school.used_indicator" => { "$exists" => false } }, { "school.used_indicator" => false } ] }
            used_indicator_staff = { "$or" => [ { "school.used_indicator" => { "$exists" => false } }, { "school.used_indicator" => false } ] }
          end

          matchUsedIndicator = {
            '$match' => used_indicator
          }
          pipeline.push(matchUsedIndicator)
        end

        projectMain = {
          "$project" => {
            :_id => false,
            :type => "$school.type",
            :city_name => "$school.city_name",
            :city_id => "$school.city_id",
            :state_name => "$school.state_name",
            :state_id => "$school.state_id"
          }
        }
        sortMain = { "$sort" => { "state_name" => 1, "city_name" => 1 } }
        pipeline.push(projectMain, sortMain)

        survey_responses = SurveyResponse.collection.aggregate(pipeline, :allow_disk_use => true, :read => { :mode => :secondary_preferred }).to_a

        @responseGroup = Hash.new
        survey_responses.each do |resp|
          if !@responseGroup[resp[:state_name]]
            statesIds.push(resp[:state_id])
            @responseGroup[resp[:state_name]] = {}
          end

          if !@responseGroup[resp[:state_name]][resp[:type]]
            @responseGroup[resp[:state_name]][resp[:type]] = {}
            if resp[:type] != "Municipal"
              @responseGroup[resp[:state_name]][resp[:type]][:quantity] = 0
            end
          end

          if resp[:type] == "Municipal"
            if !@responseGroup[resp[:state_name]][resp[:type]][resp[:city_name]]
              citiesIds.push(resp[:city_id])
              @responseGroup[resp[:state_name]][resp[:type]][resp[:city_name]] = {}
              @responseGroup[resp[:state_name]][resp[:type]][resp[:city_name]][:quantity] = 0
            end
            @responseGroup[resp[:state_name]][resp[:type]][resp[:city_name]][:quantity] += 1
          else
            @responseGroup[resp[:state_name]][resp[:type]][:quantity] += 1
          end
        end


        matchTypeMunicipal = {
          '$match' => {
            '$and' => [
              used_indicator_staff,
              {
                "type" => "Municipal",
                "state_id" => { "$in" => statesIds},
                "city_id" => { "$in" => citiesIds}
              }
            ]
          }
        }
        groupMunicipal = {
          "$group" => {
            :_id => {
              "type": "$type",
              "city_name": "$city_name",
              "state_name": "$state_name"
            },
            :teachers => { "$sum" => "$staff_count" }
          }
        }
        matchTypeEstadual = {
          '$match' => {
            '$and' => [
              used_indicator_staff,
              {
                "type" => "Estadual",
                "state_id" => { "$in" => statesIds}
              }
            ]
          }
        }
        groupEstadual = {
          "$group" => {
            :_id => {
              "type": "$type",
              "state_name": "$state_name",
            },
            :teachers => { "$sum" => "$staff_count" }
          }
        }

        staff_count_municipal = School.collection.aggregate([matchTypeMunicipal, groupMunicipal], :allow_disk_use => true, :read => { :mode => :secondary_preferred }).to_a
        staff_count_estadual = School.collection.aggregate([matchTypeEstadual, groupEstadual], :allow_disk_use => true, :read => { :mode => :secondary_preferred }).to_a

        types = ["Estadual", "Municipal"]
        @responseGroup.each do |resp|
          types.each do |type|
            if resp[1] && resp[1][type]
              if type == "Estadual"
                staff = staff_count_estadual.select { |item| item[:_id][:type] == type && item[:_id][:state_name] == resp[0] }.first
                resp[1][type][:target] = staff[:teachers]
              elsif type == "Municipal"
                resp[1][type].each do |key, value|
                  staff = staff_count_municipal.select { |item| item[:_id][:type] == type && item[:_id][:state_name] == resp[0] && item[:_id][:city_name] == key }.first
                  value[:target] = staff[:teachers]
                end
              end
            end
          end
        end

        render json: (@responseGroup).as_json()
      end

      def list_teachers_by_competences
        pipeline = Array.new
        survey_id = params[:survey_id]
        dateStart = params[:start].to_s != "" ? params[:start].to_datetime : -12.month.from_now
        dateEnd = params[:end].to_s != "" ? (params[:end]+"T23:59:59").to_datetime : 1.day.from_now
        used_indicator = []

        matchSurveyResponses = {
          "$match" => {
            "$and" => [
              { "submitted_at" => { "$gte" => dateStart, "$lte" => dateEnd } },
              { "survey_id"=> BSON::ObjectId(survey_id) },
              { "status"=> "Complete" }
            ]
          }
        }
        pipeline.push(matchSurveyResponses)

        if params[:used_indicator] && params[:used_indicator].to_s != ""
          if params[:used_indicator].to_s == "true"
            used_indicator.push({ "school.used_indicator" => true })
          elsif params[:used_indicator].to_s == "false"
            used_indicator.push({ "$or" => [ { "school.used_indicator" => { "$exists" => false } }, { "school.used_indicator" => false } ] })
          end

          matchUsedIndicator = {
            "$match" => {
              "$and" => used_indicator
            }
          }
          match_filter_global.concat(matchUsedIndicator)
        end

        lookupSchool = {
          "$lookup" => {
            :from => "schools",
            :localField => "school_id",
            :foreignField => "_id",
            :as => "school"
          }
        }
        unwindSchool = { '$unwind' => "$school" }
        matchFilterSchool = {
          "$match" => {
            "$and" => match_filter_global
          }
        }
        lookupUser = {
          "$lookup" => {
            :from => "users",
            :localField => "user_id",
            :foreignField => "_id",
            :as => "user"
          }
        }
        unwindUser = { '$unwind' => "$user" }
        matchFilterUser = {
          "$match" => {
            "$and" => match_filter_user
          }
        }
        unwindResults = { '$unwind' => "$results" }
        matchSpecific = {
          '$match' => {
            '$and' => [
              { "results.name" => { "$regex" => params[:area].to_s, "$options": "i" } },
              { "results.name" => { "$regex" => params[:competence].to_s, "$options": "i" } },
              { "results.value" => params[:nivel].to_i }
            ]
          }
        }
        projectMain = {
          "$project" => {
            :_id => false,
            :school_name => "$school.name",
            :user_id => "$user._id",
            :user_name => { "$cond": { if: "$user.sharing", then: "$user.name", else: "Anônimo" } },
            :sharing => "$user.sharing",
            :email => { "$cond": { if: "$user.sharing", then: "$user.email", else: "-" } },
            :stages => "$user.stages",
            :knowledges => "$user.knowledges",
            :type => "$school.type"
          }
        }
        sortMain = { '$sort' => { "user_name" => 1, "school_name" => 1 } }
        pipeline.push(lookupSchool, unwindSchool, matchFilterSchool, lookupUser, unwindUser, matchFilterUser, unwindResults, matchSpecific, projectMain, sortMain)
        
        @return = SurveyResponse.collection.aggregate(pipeline, :allow_disk_use => true, :read => { :mode => :secondary_preferred }).to_a

        render json: (@return).as_json()
      end

      protected

      def match_filter_global
        match = []
        user = current_user

        if !params[:level]
          params[:level] = "rede"
        end

        #GEOS
        if user.admin? 
          if params[:level] == "pais"
            match.push({ "school.country_id" =>  user.country_id })
          elsif params[:level] == "rede"
            match.push({ "school.affiliation_id" => user.affiliation_id })
            if params[:school] && params[:school].to_s != ""
              match.push({ "school._id" => BSON::ObjectId(params[:school]) })
            end
            #Country
            if params[:country_id] && params[:country_id].to_s != ''
              match.push({ "school.country_id" =>  BSON::ObjectId(params[:country_id]) })
            else
              match.push({ "school.country_id" =>  user.country_id })
            end
            #Province
            if params[:province_id] && params[:province_id].to_s != ''
              match.push({ "school.province_id" =>  BSON::ObjectId(params[:province_id]) })
              #State
              if params[:state_id ] && params[:state_id ].to_s != ''
                match.push({ "school.state_id" =>  BSON::ObjectId(params[:state_id ]) })
                #City
                if params[:city_id ] && params[:city_id ].to_s != ''
                  match.push({ "school.city_id" =>  BSON::ObjectId(params[:city_id ]) })
                end
              end
            end
          end
        end

        if match.length <= 0
          match = [{}]
        end

        match
      end

      def match_filter_user
        match = []
        match.push({ "user" => { '$ne' => [] }})

        if params[:knowledge] && params[:knowledge].to_s != ""
          match.push({ "user.knowledges" =>  params[:knowledge] })
        end

        if params[:teaching_stage] && params[:teaching_stage].to_s != ""
          match.push({ "user.stages" =>  params[:teaching_stage] })
        end

        match
      end

    end
  end

  def build_options(options_response)
    arr = []
    if options_response.instance_of? String
      hash = {}
      arr.push(hash[options_response] = options_response)
    else
      options_response.each do |e|
        hash = {}
        hash[e] = e
        arr.push(hash)
      end
    end
  end

end
