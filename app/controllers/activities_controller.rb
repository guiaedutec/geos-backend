class ActivitiesController < AdminController
  before_action :set_activity, only: [:show, :edit, :update, :destroy]

  def index
    @activities = Activity.page(params[:page])
  end

  def new
    @activity = Activity.new
  end

  def show
  end

  def create
    @activity = Activity.new(activity_params)

    respond_to do |format|
      if @activity.save
        format.html { redirect_to @activity, notice: 'Activity was successfully created.' }
        format.json { render :show, status: :created, location: @activity }
      else
        format.html { render :new }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @activity.update(activity_params)
        format.html { redirect_to @activity, notice: 'Activity was successfully updated.' }
        format.json { render :show, status: :ok, location: @activity }
      else
        format.html { render :edit }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @activity.destroy
    respond_to do |format|
      format.html { redirect_to activities_url, notice: 'Activity was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def search
    @activity = Activity.full_text_search(params[:query]).page(params[:page]).per(100)
    respond_to do |format|
      format.js
    end
  end

  private
  def set_activity
    @activity = Activity.find(params[:id])
  end
  def activity_params
    params.require(:activity).permit(:title, :description, :title_file_upload, :file_upload, :is_state, :type)
  end
end
