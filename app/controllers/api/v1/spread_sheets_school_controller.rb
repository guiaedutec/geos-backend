module Api
  module V1
    class SpreadScheetsSchoolController < ApiController
      require 'csv'

      before_action :authenticate_user!
      before_action :authenticate_admin!

      def upload_schools
        @objListError = []
        inepIds = Array.new
        user = current_user
        type = nil
        if user.profile.to_s == "admin_state"
          type = 'Estadual'
        elsif user.profile.to_s == "admin_city"
          type = 'Municipal'
        end
        schools = Array.new
        invalid = false
        if !user.nil?
          schoolValidations = Array.new
          if !params["xls"].nil?
            params["xls"].each_with_index do |xls, idx|
              begin
                schoolValidation = SpreadSheetSchool.new
                school = School.new
                schoolValidation.line = idx + 1

                xls.each_with_index do |value, index|
                  if xls.length > 18
                    invalid = true
                    schoolValidation.errors[:not_found_columns] << "Não possui o número de colunas válidas"
                  end
                  if !value.blank?
                    if (value == "0" || value == "1")
                      value = value.to_i
                    end
                    if value === "0"
                      value = value.to_i
                    end
                  end
                  if (index == 0)
                   if !value.blank?
                      valuea = SpreadScheetsSchoolController.convertStringToInteger(value)
                      if valuea.instance_of? Fixnum
                        if valuea > 0
                          inep_code = valuea
                          school.inep_code = inep_code
                          inepIds.push(inep_code)
                          schoolValidation.inep_code = inep_code
                          school.inep_code = inep_code
                        end
                      else
                        schoolValidation.inep_code = ''
                        school.inep_code = ''
                      end
                    end
                  elsif (index == 1)
                    name = value
                    school.name = name
                    schoolValidation.name = name
                  elsif (index == 2)
                    value = SpreadScheetsSchoolController.convertStringToInteger(value)
                    if value.instance_of? Fixnum
                      if value >= 0
                        staff_count = value
                        school.staff_count = staff_count
                        schoolValidation.staff_count = staff_count
                      end
                    end
                  elsif (index == 3)
                    avalue = SpreadScheetsSchoolController.convertStringToInteger(value)
                    if avalue.instance_of? Fixnum
                      if avalue >= 0
                        student_diurnal_count = avalue
                        school.student_diurnal_count = student_diurnal_count
                        schoolValidation.student_diurnal_count = student_diurnal_count
                      end
                    end
                  elsif (index == 4)
                    value = SpreadScheetsSchoolController.convertStringToInteger(value)
                    if value.instance_of? Fixnum
                      if value >= 0
                        student_vespertine_count = value
                        school.student_vespertine_count = student_vespertine_count
                        schoolValidation.student_vespertine_count = student_vespertine_count
                      end
                    end
                  elsif (index == 5)
                    value = SpreadScheetsSchoolController.convertStringToInteger(value)
                    if value.instance_of? Fixnum
                      if value >= 0
                        student_nocturnal_count = value
                        school.student_nocturnal_count = student_nocturnal_count
                        schoolValidation.student_nocturnal_count = student_nocturnal_count
                      end
                     end

                  elsif (index == 6)
                    value = SpreadScheetsSchoolController.convertStringToInteger(value)
                    if value.instance_of? Fixnum
                      if value >= 0
                        student_full_count = value
                        school.student_full_count = student_full_count
                        schoolValidation.student_full_count = student_full_count
                      end
                    end
                  elsif (index == 7)
                    if !value.blank?
                      if (value.is_a? Fixnum)
                        kindergarten = SpreadScheetsSchoolController.trueOrFalse(value)
                        schoolValidation.kindergarten = kindergarten.to_s
                        school.kindergarten = kindergarten
                      end
                    end
                  elsif (index == 8)
                    if !value.blank?
                      if (value.is_a? Fixnum)
                        elementary_1 = SpreadScheetsSchoolController.trueOrFalse(value)
                        school.elementary_1 = elementary_1
                        schoolValidation.elementary_1 = elementary_1.to_s
                      end
                    end
                  elsif (index == 9)
                    if !value.blank?
                      if (value.is_a? Fixnum)
                        elementary_2 = SpreadScheetsSchoolController.trueOrFalse(value)
                        school.elementary_2 = elementary_2
                        schoolValidation.elementary_2 = elementary_2.to_s
                      end
                    end
                  elsif (index == 10)
                    if !value.blank?
                      if (value.is_a? Fixnum)
                        highschool = SpreadScheetsSchoolController.trueOrFalse(value)
                        school.highschool = highschool
                        schoolValidation.highschool = highschool.to_s
                      end
                    end
                  elsif (index == 11)
                    if !value.blank?
                      if (value.is_a? Fixnum)
                        technical = SpreadScheetsSchoolController.trueOrFalse(value)
                        school.technical = technical
                        schoolValidation.technical = technical.to_s
                      end
                    end
                  elsif (index == 12)
                    if !value.blank?
                      if (value.is_a? Fixnum)
                        adult = SpreadScheetsSchoolController.trueOrFalse(value)
                        school.adult = adult
                        schoolValidation.adult = adult.to_s
                      end
                    end
                  elsif (index == 13)
                    location_type = value
                    school.location_type = location_type
                    schoolValidation.location_type = location_type
                  elsif (index == 14)
                    regional = value
                    school.regional = regional
                    schoolValidation.regional = regional
                  elsif (index == 15)
                    observations = value
                    school.observations = observations
                    schoolValidation.observations = observations
                  elsif (index == 16)
                    value = SpreadScheetsSchoolController.convertStringToInteger(value)
                    schoolValidation.type = type
                    city = City.where(ibge_code: value.to_i.to_s).first
                    if !city.nil?
                      state = State.find_by(_id: city.state_id)
                      school.city = city.id
                      school.state_id = state.id
                      school.type = type
                      schoolValidation.city = city._id
                      schoolValidation.state = state.id
                    end
                  elsif (index == 17)
                    manager = Manager.where(email: value).first
                    if !manager.nil?
                      school.manager = manager
                      schoolValidation.manager = manager.id
                    end
                  end
                end
                schools.push(school)
                schoolValidation.school = school
                if schoolValidation.valid? == false
                  invalid = true
                end
                  schoolValidations.push(schoolValidation)
              rescue Exception => e
                Rails.logger.error e.message
              end
            end
          end


          if (invalid == false)

            @schoolList = School.where(inep_code: {"$in" => inepIds})
            schools.each_with_index do |sc, index|
              @s = SpreadScheetsSchoolController.findSchoolByInep(@schoolList, sc.inep_code)


              if @s.nil?
                sc.is_school_imported = true
                sc.save
                sc.errors.full_messages
              else
                @s.update_attributes(
                    inep_code: sc.inep_code,
                    name: sc.name,
                    staff_count: sc.staff_count,
                    student_diurnal_count: sc.student_diurnal_count,
                    student_vespertine_count: sc.student_vespertine_count,
                    student_nocturnal_count: sc.student_nocturnal_count,
                    student_full_count: sc.student_full_count,
                    kindergarten: sc.kindergarten,
                    elementary_1: sc.elementary_1,
                    elementary_2: sc.elementary_2,
                    highschool: sc.highschool,
                    technical: sc.technical,
                    adult: sc.adult,
                    location_type: sc.location_type,
                    regional: sc.regional,
                    observations: sc.observations,
                    city_id: sc.city.id,
                    state_id: sc.state.id,
                    manager: sc.manager,
                    is_school_imported: true
                )
              end
            end
          else
            schools.each_with_index do |sc, index|
              if (!schoolValidations[index].errors.nil?)
                strArray = []
                schoolValidations[index].errors.each do |attr, msg|
                  strArray.push(msg)
                end
                schoolValidations[index].t_error = strArray
                if (!strArray.empty?)
                  @objListError.push(schoolValidations[index])
                end
              end
            end
          end
        else
          schools.each_with_index do |sc, index|
            if (!schoolValidations[index].errors.nil?)
              strArray = []
              schoolValidations[index].errors.each do |attr, msg|
                strArray.push(msg)
              end
              schoolValidations[index].t_error = strArray
              if (!strArray.empty?)
                @objListError.push(schoolValidations[index])
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

      def self.findSchoolByInep(schoolList, inep_code)
        retrieve = nil
        schoolList.each do |s|
          if s.inep_code == inep_code
            retrieve = s
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
