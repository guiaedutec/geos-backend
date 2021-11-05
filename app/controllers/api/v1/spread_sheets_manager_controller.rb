module Api
  module V1
    class SpreadScheetsManagerController < ApiController
      require 'csv'

      before_action :authenticate_user!
      before_action :authenticate_admin!

      def upload_manageres
        @objListError = []
        emails = Array.new
        user = current_user
        validManagers = Array.new
        invalidManagers = Array.new
        invalid = false
        schools = Array.new
        if !user.nil?
          managerValidations = Array.new
          if !params["xls"].nil?
            params["xls"].each_with_index do |xls, idx|
              begin
                managerValidation = SpreadSheetManager.new
                manager = Manager.new
                managerValidation.line = idx + 1
                theyHaveSchool = ""

                xls.each_with_index do |value, index|
                  if (index == 0)
                    name = value
                    manager.name = name
                    managerValidation.name = name
                  elsif (index == 1)
                    email = value.strip
                    manager.email = email
                    emails.push(email)
                    managerValidation.email = email
                  elsif (index == 2)
                    phone = value
                    manager.phone = phone
                    managerValidation.phone = phone
                  elsif (index == 3)
                    theyHaveSchool = value
                  end
                end
                if user.profile.to_s == "admin_state"
                  manager.state_id = user.state.id.to_s
                  manager.type = 'Estadual'
                elsif user.profile.to_s == "admin_city"
                  manager.city_id = user.city.id.to_s
                  manager.state_id = user.state.id.to_s
                  manager.type = 'Municipal'
                end
                if managerValidation.valid? == false
                  invalid = true
                  invalidManagers.push(managerValidation)
                else
                  validManagers.push(manager)
                  schools.push(theyHaveSchool)
                end
                managerValidations.push(managerValidation)
              rescue Exception => e
                 Rails.logger.error e.backtrace.join("\n")
              end
            end
          end
          @managerList = Manager.where(email: {"$in" => emails})
          managerListArray = Array.new
          @managerList.each do |s|
            managerListArray.push(s)
          end
          @schoolList = School.where(inep_code: {"$in" => schools})
          schoolListArray = Array.new
          @schoolList.each do |s|
            schoolListArray.push(s)
          end
          validManagers.each_with_index do |sc, index|
            @s = SpreadScheetsManagerController.findManagerByEmail(managerListArray, sc.email)

            if @s.nil?
              sc.is_principal_profile_imported = true

              if schools[index] && schools[index] != "" && sc.save != false
                school = SpreadScheetsManagerController.findSchoolByInep(schoolListArray, schools[index])
                if !school.nil?
                  school.manager = @s
                  school.save
                end
              end
            else

              @s.update_attributes(
                  email: sc.email,
                  name: sc.name,
                  phone: sc.phone,
                  city: sc.city,
                  state: sc.state,
                  type: sc.type,
                  is_principal_profile_imported: true
              )
              if schools[index] && schools[index] != ""
                school = SpreadScheetsManagerController.findSchoolByInep(schoolListArray, schools[index])
                if !school.nil?
                  school.manager = @s
                  school.save
                end
              end
            end
          end
          if (invalid == true)
            invalidManagers.each_with_index do |sc, index|
              if (!sc.errors.nil?)
                strArray = []
                sc.errors.each do |attr, msg|
                  strArray.push(msg)
                end
                sc.t_error = strArray
                if (!strArray.empty?)
                  @objListError.push(sc)
                end
              end
            end
          end
        end
        render json: @objListError.to_json
      end

      def self.convertStringToInteger(str)
        retrieve = " "
        begin
          retrieve = Integer(str)
        rescue Exception => e

        end
        return retrieve
      end

      def self.trueOrFalse(obj)
        retrive = false
        if obj == 1
          retrieve = true
        else
          retrieve = false
        end
       return retrieve
      end

      def self.findManagerByEmail(managerList, email)
        retrieve = nil
        managerList.delete_if do |s|
          if s.email == email
            retrieve = s
            true
          end
        end
        return retrieve
      end

      def self.findSchoolByInep(schoolList, inep)
        retrieve = nil
        schoolList.delete_if do |s|
          if s.inep_code == inep.to_s
            retrieve = s
            true
          end
        end
        return retrieve
      end

      def render_stepone_upload
        user = current_user
        auxArrayIndex = 0
        auxArray = Array.new
        dirTmp = File.join(Rails.root, "tmp/#{user._id}")

        FileUtils.mkdir_p(dirTmp) unless File.directory?(dirTmp)

        fileCompletePath = File.join(dirTmp, params[:file].original_filename)
        allowed_partial fileCompletePath

        File.open(@address, "wb") do |f|
          f.write(params[:file].read)
        end
        populateIt = false
        case File.extname(params[:file].original_filename)
          when '.xls' then
            file = Roo::Excel.new(@address)
            populateIt = true
          when '.xlsx' then
            file = Roo::Excelx.new(@address)
            populateIt = true
          when '.csv' then
            file = Roo::CSV.new(@address)
            populateIt = true
          else
            logger.error("Formato de arquivo #{File.extname(fileName)} não permitido, arquivo #{fileName}. Os tipos permitidos são xls, xlsx e csv.")
            populateIt = false
        end
        File.delete(@address) if File.exist?(@address)
        if (populateIt) then
          rowFileIndex = file.last_row
          (1..rowFileIndex).each do |i|
            auxArray[auxArrayIndex] = file.row(i)
            auxArrayIndex = auxArrayIndex + 1
          end

        end
        render json: auxArray.to_json
      end

      def allowed_partial address
        address = address[0] == "/" ? address[1..-1] : address
        @address = address
      end
    end
  end
end
