# frozen_string_literal: true
module Api
  module V1
    class PlansController < ApplicationController
      respond_to :json, :pdf, :xls
      before_action :authenticate_user!, only: [:thematics]

      def thematics
        if params[:survey_id]
          @thematics = SurveySection.includes(:thematics).where(survey_id: params[:survey_id], has_question: true, has_feedback: true).ordered
         
        end

        render json: @thematics.as_json(:include => [:thematics])
        @thematics = nil
      end

      def survey_answer
        Resque.enqueue(SurveyResponse, current_user.to_param)
        render json: {}
      end

      def survey_answers
        @school_answer_search = SchoolAnswerSearch.new(search_params)
        puts @school_answer_search
        respond_to do |format|
          format.json
          format.xls do
            file = StringIO.new
            @school_answer_search.to_xls(file)
            send_data file.string.force_encoding('binary'), filename: 'respostas.xls'
          end
        end
      end

      def survey_answers_details
        @school_answer_search_details = SchoolAnswerSearch.new(search_params)
        puts @school_answer_search_details
        respond_to do |format|
          format.json
        end
      end

      def survey_answers_query
        puts search_params
        @school_answer_search = SchoolAnswerSearch.new(search_params)
        @school_answer_search.asc = @school_answer_search.answered_sample_count
        @school_answer_search.tsc = @school_answer_search.total_sample_count
        @school_answer_search.ac = @school_answer_search.answered_count
        @school_answer_search.tc = @school_answer_search.total_count
        @school_answer_search.pc = @school_answer_search.pages_count

        puts @school_answer_search.ac
        puts @school_answer_search.tc
        render json: @school_answer_search.to_json
      end

      def survey_response
        raise 'error' unless current_user.school.present?
        @school = current_user.school
        @survey_response = current_user.survey_response
        raList = ResponseAnswer.where(:user_id => current_user.id, :school_id => @school.id)
        responses = Array.new
        raList.each do |resp|
          responses.push(resp)
        end
        @section_1_scores = @survey_response.position_section_scores(1, responses, @school)
        @section_2_scores = @survey_response.position_section_scores(2, responses, @school)
        @section_3_scores = @survey_response.position_section_scores(3, responses, @school)
        @section_4_scores = @survey_response.position_section_scores(4, responses, @school)
        respond_to do |format|
          format.pdf do
            render pdf: 'survey_response',
                   #zoom: 1.5,
                   layout: 'pdf', orientation: 'Landscape',
                   file: "#{Rails.root}/app/views/api/v1/schools/survey_response_#{@school.state.to_s.downcase}.pdf.haml",
                   margin:  { top: 0, bottom: 0, left: 0, right: 0 }, show_as_html: params.key?('debug')
          end
        end
      end

      def survey_feedback
        raise 'error' unless current_user.present?

        @user = current_user
        survey_id = params[:id_survey]
        @survey = Survey.find_by(:id => survey_id)
        response_id = params[:id_response]
        @survey_response = SurveyResponse.where(:id => response_id).first

        @feedbacks = nil
        if !@user.nil?
          @school = nil
          if @user.profile.to_s == "admin_state"
            state = @user.state.id.to_s
            @school = School.where(:state => state, :type => 'Estadual').first
          elsif @user.profile.to_s == "admin_city"
            city = @user.city.id.to_s
            @school = School.where(:city => city, :type => 'Municipal').first
          elsif @user.profile.to_s == "principal" || @user.profile.to_s == "teacher"
            state = @survey_response.school.state_id.to_s
            city = @survey_response.school.city_id.to_s
            @school = @survey_response.school
          end

          if @school.type == "Estadual"
            @feedbackImages = FeedbackImg.where(:type => "Estadual", :state => @school.state)
            @feedbacks_local = Feedback.where(:state => state, :type => 'Estadual', :survey => survey_id).order(:page => :asc).to_a
          elsif @school.type == "Municipal"
            @feedbackImages = FeedbackImg.where(:type => "Municipal", :city => @school.city)
            @feedbacks_local = Feedback.where(:city => city, :type => 'Municipal', :survey => survey_id).order(:page => :asc).to_a
          elsif @school.type == "Particular"
            @school.name = @user.institution_name
            @feedbackImages = FeedbackImg.where(:type => "Particular", :city => @school.city)
            @feedbacks_local = Feedback.where(:city => city, :type => 'Particular', :survey => survey_id).order(:page => :asc).to_a
          elsif @school.type == "Federal"
            @feedbackImages = FeedbackImg.where(:type => "Federal", :city => @school.city)
            @feedbacks_local = Feedback.where(:city => city, :type => 'Federal', :survey => survey_id).order(:page => :asc).to_a
          end
          @feedbacks_all = Feedback.where(:survey => survey_id, city: nil, state: nil).order('page ASC').to_a
          @feedbacks = Array.new

          if @feedbacks_local.count > 0
            @feedbacks_all.each do |fe|
              local = false
              @feedbacks_local.delete_if do |fe_local|
                if fe.id == fe_local.feedback_id
                  @feedbacks.push(fe_local)
                  local = true
                  true
                end
              end
              unless local
                @feedbacks.push(fe)
              end
            end
            if @feedbacks_local.count > 0
              @feedbacks_local.each do |fe_local|
                @feedbacks.insert(@feedbacks.count - 1, fe_local)
              end
            end
          else
            @feedbacks = @feedbacks_all
          end

          @survey_sections = SurveySection.where(:survey_id => survey_id, :has_result => true).order(:position => :asc)
          if @survey_response
            responses = @survey_response.response_answers 
          else
            responses = nil
          end

          @scores = Array.new
          @results = Array.new
          @survey_section_feedbak = Array.new
          @survey_sections.each do |sec, index|
            if sec.has_result && @survey_response
              @scores.push(@survey_response.section_scores(sec, responses, @school))

              @survey_response.results.each do |result|
                if result["survey_section_id"] == sec.id
                  @results.push(result)
                end
              end
            end
            if sec.has_feedback
              @survey_section_feedbak.push(sec)
            end
          end

          feedbacks_local = @feedbacks.to_a

          if @user.profile.to_s == "principal" || @user.profile.to_s == "teacher"
            results = @survey_response.results

            @survey_section_feedbak.each do |sec|
              localIndex = 0;
              result_section = results.select { |result| result["survey_section_id"] == sec.id }
              feedbacks_local.delete_if do |feedback|
                if feedback.survey_section_id == sec.id
                  localIndex += 1
                  if localIndex != result_section[0]["value"]
                    true
                  end
                end
              end
            end

            @feedbacks = feedbacks_local

          end
        end
        render pdf: 'survey_response',
               layout: 'pdf', orientation: 'Landscape',
               file: "#{Rails.root}/app/views/api/v1/api/survey_feedback_#{@survey.type.downcase}.pdf.haml",
               margin:  { top: 0, bottom: 0, left: 0, right: 0 }, show_as_html: params.key?('debug')
      end

      def school_plans_answers
        @school_answer_search_details = SchoolAnswerSearch.new(search_params)
        puts @school_answer_search_details
        respond_to do |format|
          format.json
          format.xls do
            file = StringIO.new
            @school_answer_search_details.to_xls(file)
            send_data file.string.force_encoding('binary'), filename: 'respostas.xls'
          end
        end
      end

      def school_plans_results
        @institution_priorities = PlanSchoolPriority.where(:institution => current_user.institution_id)
        @total_schools = School.where(search_params).with_plan.count
        respond_to do |format|
          format.json
        end
      end

      def generate_scores
        raise 'error' unless params[:id_response].present?
        user = current_user
        @response = SurveyResponse.includes(:response_answers, :school).find(params[:id_response])
        valid = false
        if !user.nil? && @response.perform
          @response.school.update_attributes({:answered => true})
          user.update_attributes(
            has_answered_survey: true
          )
          valid = true
        end
        render json: valid.to_json
      end

      def spreadsheets
      	if params[:school_id]
      	  @spreadsheets = SpreadSheet.where({:colVEscola => params[:school_id]})
      	else
      	  @spreadsheets = SpreadSheet.all
      	end
      	render json: @spreadsheets.as_json
      end

      def user_institution
        raise 'error' unless current_user.present?
        user = current_user
        if(user.school.type == "Estadual")
          @instititution = Institution.where(:state_id => user.school.state_id)
        elsif
          @instititution = Institution.where(:city_id => user.school.city_id)
        end

        render json: @instititution.as_json
        user = nil
      end

    protected
      def search_params
        puts params
        basic_search_params = {
          query: params[:q],
          sort_field: params[:sort],
          sort_direction: params[:sort_dir],
          page: params[:page],
          filters: params[:filters]
        }

        #monitor state
        if current_user.monitor_state?
          basic_search_params[:type] = "Estadual"
          basic_search_params[:state] = current_user.state
        end

        #monitor city
        if current_user.monitor_city?
          basic_search_params[:type] = "Municipal"
          basic_search_params[:state] = current_user.state
          basic_search_params[:city] = current_user.city
        end

        #monitor state regional
        if current_user.monitor_state_regional?
          basic_search_params[:type] = "Estadual"
          basic_search_params[:state] = current_user.state
          basic_search_params[:regional] = current_user.regional
        end

        #monitor city regional
        if current_user.monitor_city_regional?
          basic_search_params[:type] = "Municipal"
          basic_search_params[:state] = current_user.state
          basic_search_params[:city] = current_user.city
          basic_search_params[:regional] = current_user.regional
        end

        #admin state
        if current_user.admin_state?
          basic_search_params[:type] = "Estadual"
          basic_search_params[:state] = current_user.state
        end

        #admin city
        if current_user.admin_city?
          basic_search_params[:city] = current_user.city
          basic_search_params[:state] = current_user.state
          basic_search_params[:type] = "Municipal"
        end

        #super admin
        if current_user.super_admin?
          if params[:city_id]
            basic_search_params[:city] = City.find(params[:city_id])
          end
          if params[:state_id]
            basic_search_params[:state] = State.find(params[:state_id])
          end
          if params[:network]
            basic_search_params[:type] = params[:network]
          end
        end

        #regional
        if params[:regional]
          basic_search_params[:regional] = params[:regional]
        end

        #regional
        if params[:institution]
          basic_search_params[:institution] = params[:institution]
        end

        puts basic_search_params.inspect

        basic_search_params
      end
    end
  end
end
