module Api
  module V1
    class DashboardController < ApiController
      before_action :authenticate_admin!

      def retrieve_all_states
        @states = State.all.order('name ASC')
        render json: @states.as_json
      end

      def retrieve_cities_by_state
        @cities = nil
        if !params['id'].nil?
          @cities = City.where(:state_id => params['id']).order('name ASC')
        end
        render json: @cities.as_json
        @cities = nil
      end

      def index
        dash = []
        page = nil
        if !params[:page].nil?
          page = params[:page]
        else
          page = 1
        end
        @dashboard = []
        user = current_user

        # GEOS
        if user.super_admin?
          #Get country_id and find all affiliation by user country_id
          affiliation = Institution.find_by(:_id => user.affiliation_id)
          if (!params[:country_id].present?)
            affiliationsByCountry = Institution.where(:country_id => affiliation.country_id)
          else
            affiliationsByCountry = Institution.where(:country_id => params[:country_id])
          end
          affiliationsByCountry.each do |aff|
            da = Dash.new(nil, nil, nil, nil, nil, user,aff._id)
            @dashboard.push(da)
          end
        else
          da = Dash.new(nil, nil, nil, nil, nil, user,nil)
          @dashboard.push(da)
        end
        render json: @dashboard.as_json
      end

      def total_of_networks
        count = Dash.total_of_networks(current_user, get_schools_by_profile)
        output = {'count' => count}.to_json
        render :json => output
      end

      def amount_of_networks
        schools = get_schools_by_profile.where(answered: true)
        count = Dash.amount_of_networks(current_user, schools)
        output = {'count' => count}.to_json
        render :json => output
      end

      def number_of_schools
        count = Dash.number_of_schools(current_user, get_schools_by_profile)
        output = {'count' => count}.to_json
        render :json => output
      end

      def number_of_schools_with_responses
        schools = get_schools_by_profile.where(answered: true)
        count = Dash.number_of_schools(current_user, schools)
        output = {'count' => count}.to_json
        render :json => output
      end

      def number_of_responses
        count = Dash.number_of_responses(params[:network_type])
        output = {'count' => count}.to_json
        render :json => output
      end

      def completed_networks
        count = Dash.completed_networks(params[:network_type])
        output = {'count' => count}.to_json
        render :json => output
      end
    end
  end
end
