class UsersController < AdminController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.page(params[:page])
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  def getUserInfo
    @user = User.where(:_id => params[:id])
    respond_to do |format|
      format.json { render json: @user[0] }
    end
  end


  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def search
    @users = User.full_text_search(params[:query]).page(params[:page]) #.per(100)
    #@users = User.or( {name: params[:query]},{email: params[:query]} ).page(params[:page]).per(100)
    respond_to do |format|
      format.js
    end
  end

 def valid_principal

   school = School.where(:_id => params[:schoolId]).first
   valid = false

    if !school.manager_id.nil?

      if school.manager.email == params[:email]
       valid = true
      else
        valid = false
      end
    else
      valid = true
    end

    respond_to do |format|
       format.json {
               render :json => {:valid => valid }.to_json, :status => 200
        }
    end
  end


private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:profile, :name, :password, :email, :born, :affiliation_id, :country_id, :province_id, :state_id, :city_id, :school_id, :stages, :knowledges, :locked, :affiliation_name, :responsible_name, :responsible_email, :responsible_phone_number)
  end
end
