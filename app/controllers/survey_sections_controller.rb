class SurveySectionsController < AdminController
  before_action :set_survey_section, only: [:show, :edit, :update, :destroy]

  # GET /survey_sections
  # GET /survey_sections.json
  def index
    @survey_sections = SurveySection.page(params[:page]).per(100)
  end

  # GET /survey_sections/1
  # GET /survey_sections/1.json
  def show
  end

  # GET /survey_sections/new
  def new
    @survey_section = SurveySection.new
  end

  # GET /survey_sections/1/edit
  def edit
  end

  # POST /survey_sections
  # POST /survey_sections.json
  def create
    @survey_section = SurveySection.new(survey_section_params)

    respond_to do |format|
      if @survey_section.save
        format.html { redirect_to @survey_section, notice: 'Survey section was successfully created.' }
        format.json { render :show, status: :created, location: @survey_section }
      else
        format.html { render :new }
        format.json { render json: @survey_section.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /survey_sections/1
  # PATCH/PUT /survey_sections/1.json
  def update
    respond_to do |format|
      if @survey_section.update(survey_section_params)
        format.html { redirect_to @survey_section, notice: 'Survey section was successfully updated.' }
        format.json { render :show, status: :ok, location: @survey_section }
      else
        format.html { render :edit }
        format.json { render json: @survey_section.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /survey_sections/1
  # DELETE /survey_sections/1.json
  def destroy
    @survey_section.destroy
    respond_to do |format|
      format.html { redirect_to survey_sections_url, notice: 'Survey section was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

private
  # Use callbacks to share common setup or constraints between actions.
  def set_survey_section
    @survey_section = SurveySection.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def survey_section_params
    params.require(:survey_section).permit(:id,:name,:pageTitleCssClass,:position,:description,:has_feedback,:only_feedback,:has_result,:has_question,:ceil_result,:divisor,:user_type,)
  end
end
