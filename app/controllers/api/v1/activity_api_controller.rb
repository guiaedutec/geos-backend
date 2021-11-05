module Api
  module V1
    class ActivityApiController < ApiController

      def list_all_activities
        user = current_user
        state = false

        if user.admin_state?
          state = true
        end
        params[:type] ? type = params[:type] : type = "school"
        @activities = Activity.where(:is_state => state, :type => type).sort({:title => 1})

        render json: @activities.to_json
      end

      def save_user_activity
        user = current_user
        check = params[:checkbox]

        UserActivity.where(:user_id => user.id).destroy_all
        if !check.nil?
          check.each do |c|
            ua = UserActivity.new
            ua.user_id = user.id
            ua.activity_id = c
            ua.affiliation_id = user.affiliation_id
            ua.save!
          end
        end
        render json: user.to_json
      end

      def list_all_user_activities
        user = current_user
        @user_activities = UserActivity.where(user_id: user._id)
        render json: @user_activities.to_json

      end

    end
  end
end
