class RatingController < ApplicationController

  skip_before_action :verify_authenticity_token

  def index

    json = {}

    begin

      if ( (!params[:rating].nil?) && (!params[:projectId].nil?) && (params[:rating] <= 5) ) then

        dataToSave = Array.[](params[:projectId],params[:rating])
        SpreadSheet.ratingProject(dataToSave)

        json = {:data => 'success'}
      else
        json = {:data => 'Invalid Parameters'}
      end

    rescue Exception => e
      Rails.logger.error e.backtrace.join("\n")
      json = {:data => 'Invalid Request'}
    end

    respond_to do |format|
      format.json{
        render :json => json.to_json, :status => 200
      }
    end

  end

end
