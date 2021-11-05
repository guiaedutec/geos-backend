module Api
  module V1
    class FeedbackController < ApiController
      
      def get_all_by_survey
        
        I18n.locale =  (!params[:lang].nil?) ? params[:lang] :  I18n.default_locale

        survey_id = params[:id_survey]
        user = current_user
        if user.admin?
          @feedbacks = Feedback.where(:survey_id => BSON::ObjectId.from_string(survey_id)).order(:page => 1)
          render json: @feedbacks.to_json
        else
          render json: {status: 'ERROR', message:'Only the admin can perform this action', data: nil},status: :unauthorized
        end
      end

      def retrieve_seven_pages_common_devolutive
        @feedbacks = Feedback.all.limit(7)
        render json: @feedbacks.to_json
      end

      def retrieve_footer_page_common_devolutive
        @feedbacks = Feedback.where(:page => 1000)
        render json: @feedbacks.to_json
      end

      def retrieve_all_devolutive
        survey_id = params[:id_survey]
        user = current_user
        if current_user && (current_user.admin_city? || current_user.admin_state?)
          if current_user.admin_city?
            @feedbacks_local = Feedback.where(:survey_id => survey_id, :city => current_user.city, :type => 'Municipal').order(:page => :asc)
          else
            @feedbacks_local = Feedback.where(:survey_id => survey_id, :state => current_user.state, :type => 'Estadual').order(:page => :asc)
          end
          @feedbacks_all = Feedback.where(page: {"$in" => [8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27]}, :survey => survey_id, city: nil, state: nil).order('page ASC').to_a
          @feedbacks = Array.new

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
          @feedbacks.concat @feedbacks_local


          render json: @feedbacks.as_json
          @feedbacks = nil
        else
          render json: { :valid => false }.to_json
        end
      end

      def edit
        @feedback = Feedback.find(params[:id])
        render json: @feedback.to_json
      end

      def find_images_school
        user = current_user
        listUploads = nil
        listUploads = FeedbackImg.where(:affiliation_id => user.affiliation_id)

        ret = []
        if listUploads
          listUploads.each do |imgUpload|
             dev = DevolutiveImg.new
             dev._id = imgUpload._id
             dev.size = imgUpload.file_upload.size
             dev.name = imgUpload.file_upload.file.filename
             dev.url = imgUpload.file_upload.url

             ret.push(dev)
          end
        end

        render json: ret.to_json
      end

      def update_feedback
        user = current_user
        if user.admin?
          @feedback = Feedback.find(params[:id])
          
          #Adjust locale to save
          I18n.locale =  (!params[:lang].nil?) ? params[:lang] :  I18n.default_locale
          params.permit(:id, :lang, :body, :group, :title, :subtitle, :type)
          # build 'body field'
          body = Hash.new
          i = 0
          params[:body].each do |bY|
            body[i] = bY[1]
            i=i+1
          end
          # build 'group field'
          group = nil
          if params[:group].present?
            group = Hash.new
            params[:group].each do |grp|
              group[grp[0]] = grp[1]
            end
          end
          if @feedback.update_attributes(
                                          title: params[:title],
                                          subtitle: params[:subtitle],
                                          body: body,
                                          group: group,
                                          type: params[:type]
                                          )
            render json: @feedback.to_json
          else
            render json: {status: 'ERROR', message:'Can not perform this action', data: nil},status: :unprocessable_entity
          end
        else
          render json: {status: 'ERROR', message:'Only the admin can perform this action', data: nil},status: :unauthorized
        end
      end

      def save
        valid = false
        if current_user && (current_user.admin_city? || current_user.admin_state?)

          if !params[:feedback].nil?

            feedback = JSON.parse(params[:feedback])

            p feedback
            # build 'body field' with new line. A new line (paragraph) is a new position into Hash
            body = Hash.new
            arrBody = feedback['body'].split(/\n/)

            i = 0
            arrBody.each do |bY|
              body[i] = bY
              i=i+1
            end
            type = nil
            if current_user.profile.to_s == "admin_state"
              type = 'Estadual'
            elsif current_user.profile.to_s == "admin_city"
              type = 'Municipal'
            end

            if feedback['id'].nil?
              @feedback = Feedback.new
              @feedback.state = current_user.state
              @feedback.city = current_user.city
              @feedback.body = body
              @feedback.title = feedback['title']
              @feedback.subtitle = feedback['subtitle']
              @feedback.type = type
              @survey_section = SurveySection.where(:name => 'Perguntas Extra').first
              @feedback.survey = @survey_section.survey
              @feedback.survey_section = @survey_section
              @feedback.save
              valid = true
            else
              @feedback = Feedback.find(feedback['id'])
              if @feedback.city_id.nil? && @feedback.state_id.nil?
                @feedback_new = Feedback.new
                @feedback_new.state = current_user.state
                @feedback_new.city = current_user.city
                @feedback_new.body = body
                @feedback_new.title = feedback['title']
                @feedback_new.subtitle = feedback['subtitle']
                @feedback_new.type = type
                @feedback_new.survey = @feedback.survey
                @feedback_new.survey_section = @feedback.survey_section
                @feedback_new.feedback = @feedback
                @feedback_new.save
              else
                @feedback.update_attributes(
                  title: feedback['title'],
                  subtitle: feedback['subtitle'],
                  body: body,
                  type: type
                )
              end
            end

            # building pagination always
            pagination_devolutive
            valid = true
          end
        end
        render json: { :valid => valid }.to_json
      end

      def delete
        valid = false
        @feedback = Feedback.find(params[:id])
        @feedback.destroy

        # building pagination always
        pagination_devolutive
        valid = true

        render json: { :valid => valid }.to_json
      end

      def save_footer
        valid = false
        if !params[:feedback].nil?
          body = Hash.new
          body[0] = params[:feedback][:body]
          @feedback = Feedback.find(params[:feedback][:id])
          @feedback.update_attributes(
              body: body
          )
          valid = true
        end
        render json: { :valid => valid }.to_json
      end

      def upload_files

        user = current_user
        valid = false
        if !params[:file].nil?
          valid = true
          img = FeedbackImg.new
          img.file_upload = params[:file]
          img.type = user.institution.type
          img.affiliation_id = user.institution._id
          img.save
        end
        render json: { :upload => img }.to_json
      end

      def remove_file
        user = current_user

        puts 'delete ' + params[:_id]

        feedbackImg = FeedbackImg.where(:_id => params[:_id]).first

        ret =  feedbackImg.destroy()
        render json: { :valid => ret }.to_json
      end

      def pagination_devolutive
        user = current_user
        @feedbacks = Feedback.where(:type => user.institution.type, :affiliation_id => user.institution._id).order('created_at ASC')
        i = 8
        @feedbacks.each do |feedback|
          feedback.update_attributes(
              page:i
          )
          i=i+1
        end
      end
    end
  end
end
