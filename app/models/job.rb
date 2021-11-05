class Job
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Memoist

  field :user_id, type: BSON::ObjectId
  field :seq, type: Integer
  field :type, type: String
  field :status, type: Boolean
  field :finished_at, type: DateTime
  field :filename, type: String
  field :link, type: String

  default_scope -> { order_by(:created_at.asc) }

  @queue = :jobs
  def perform(user)
    complete_proccess(user)
    self && localSendEmail(user)
  end

  def export_schools_microdata(user)
    if(user.admin_country? || user.admin?)
      survey = Survey.where(type: "school").where(active: true).first
      resp = SurveyResponse.where(:status => "Complete").where(survey_id: survey['id']).first
      fields = !resp.nil? ? resp['results'].to_a : []
      names = []
      survSecIds = []
     
      fields.each do |f|
        names.push(f['name'])
        survSecIds.push(f['survey_section_id'].to_s)
      end

      columns = []
      qo = []
      c = []
      sq = []
      j = 0
      optIds = []
      survSecIds.each do |s|
        sq = SurveyQuestion.where(:survey_section_id => BSON::ObjectId.from_string(s))
        qo.push(sq.pluck('question_order'))
        c = sq.pluck('survey_question_description')
        sq.each do |k|
          for i in 1..k['survey_question_description'].length()
            str = names[j].to_s + "_" + k['question_order'].to_s + "_" + i.to_s
            columns.push(str)
            if(k['type'] == 'checkbox' || k['type'] == 'radio')
              qid = k['survey_question_description'][i-1]['id']
              optIds.push(qid)
            else
              optIds.push(nil)
            end
          end 
        end
        j = j+1
      end

      rows = ['cicle', 'unique_code', 'name', 'geographic_level_1', 'geographic_level_2', 'geographic_level_3', 'geographic_level_4',
        'affiliation', 'level_visao', 'level_competencia', 'level_recursos', 'level_infraestrutura']
      rows.concat(columns)

      surveyResp = SurveyResponse.where(:status => "Complete").where(survey_id: survey['id']).where(:type.exists => false)
      
      schools_csv = CSV.open(self.link, "w", col_sep: ",", force_quotes: true, headers: true, encoding: Encoding::UTF_8) do |row_csv|
        row_csv << rows
        
        surveyResp.each do |sr|
        
          if(user.admin_country?)
            s = School.where(id: sr['school_id']).first
            if(s['name'] != "Dummy School For Unaffiliated Users")
              if(s['country_id'] == user['country_id'])
                respV = []
                responses = ResponseAnswer.where('school_id': sr['school_id']).where('survey_response_id': sr['id']).pluck('options')
                
                respOpts = responses.flatten

                optIds.each do |oid|
                  if (respOpts.include?(oid.to_s))
                    respV.push(1)
                  else
                    respV.push(0)
                  end
                end

                cycle = s['results'].keys.first
                dataRow = [cycle, s.inep_code, s.name, s.country_name, s.state_name, s.province_name, s.city_name, s.affiliation_name,
                  s['results'][cycle]['vision_level'], s['results'][cycle]['competence_level'], s['results'][cycle]['resource_level'], 
                  s['results'][cycle]['infrastructure_level']]
                dataRow.concat(respV)
                row_csv << dataRow
              end
            end
          else
            s = School.where(id: sr['school_id']).first
            if(s['name'] != "Dummy School For Unaffiliated Users")
              respV = []
              responses = ResponseAnswer.where('school_id': sr['school_id']).where('survey_response_id': sr['id']).pluck('options')
              
              respOpts = responses.flatten

              optIds.each do |oid|
                if (respOpts.include?(oid.to_s))
                  respV.push(1)
                else
                  respV.push(0)
                end
              end

              cycle = s['results'].keys.first
              year = SurveySchedule.where(id: BSON::ObjectId.from_string(cycle)).first
              dataRow = [year['name'], s.inep_code, s.name, s.country_name, s.state_name, s.province_name, s.city_name, s.affiliation_name,
                s['results'][cycle]['vision_level'], s['results'][cycle]['competence_level'], s['results'][cycle]['resource_level'], 
                s['results'][cycle]['infrastructure_level']]
              dataRow.concat(respV)
              row_csv << dataRow
            end
          end
        end
      end
    else
      render json: {status: 'ERROR', message:'User not allowed', data: params},status: '400 '
    end
  end

  def export_teachers_microdata(user)
    if(user.admin_country? || user.admin?)
      stages = [
        "Educação Infantil",      
        "Fundamental I",      
        "Fundamental II",      
        "Ensino Médio",      
        "Educação para Jovens e Adultos",      
        "Ensino Técnico",      
        "Ensino Superior"
      ]
      knowledges = [
        "Campos de experiências",
        "Língua Portuguesa",
        "Arte", 
        "Educação Física",
        "Língua Inglesa",
        "Língua Espanhola",
        "Matemática",
        "Ciências",
        "Geografia", 
        "História",
        "Ensino Religioso",
        "Polivalente",
        "Linguagens e suas Tecnologias",
        "Matemática e suas Tecnologias",
        "Ciências da Natureza e suas Tecnologias",
        "Ciências de Humanas e Sociais Aplicadas",
        "Língua Portuguesa",
        "Arte", 
        "Educação Física",
        "Língua Inglesa",
        "Língua Espanhola",
        "Matemática",
        "Ciências",
        "Geografia",  
        "História",
        "Ensino Religioso",
        "Linguagens e suas Tecnologias",
        "Matemática e suas Tecnologias",
        "Ciências da Natureza e suas Tecnologias",
        "Ciências de Humanas e Sociais Aplicadas",
        "Ensino técnico",
        "Ciências Biológicas",
        "Engenharias",
        "Ciências da Saúde",
        "Ciências Exatas e da Terra",
        "Ciências Sociais Aplicadas",
        "Ciências Humanas",
        "Linguística, Letras e Artes",
        "Ciências Agrárias"
      ]
      formacao = [
        "Formação continuada - Em andamento",
        "Formação continuada - Concluída",
        "Graduação - Em andamento",
        "Graduação - Concluída",
        "Especialização - Em andamento",
        "Especialização - Concluída",
        "Mestrado - Em andamento",
        "Mestrado - Concluído",
        "Doutorado - Em andamento",
        "Doutorado - Concluído",
        "Pós-doutorado - Em andamento",
        "Pós-doutorado - Concluído"
      ]
      
      stagesrow = []
      for i in 1..stages.length()
        str = 'stages_' + i.to_s
        stagesrow.push(str)
      end

      knowledgesrow = []
      for i in 1..knowledges.length()
        str = 'knowledges_' + i.to_s
        knowledgesrow.push(str)
      end

      formationrow = []
      for i in 1..formacao.length()
        str = 'formation_' + i.to_s
        formationrow.push(str)
      end

      rows = ['cicle', 'id', 'unique_code', 'geographic_level_1', 'geographic_level_2', 'geographic_level_3', 'geographic_level_4',
        'affiliation'] + stagesrow + knowledgesrow + ['has_formacao_tecnologica'] + formationrow + ['authorized_data', 'level_pedagogica_pratica',
        'level_pedagogica_avaliacao', 'level_pedagogica_personalizacao', 'level_pedagogica_curadoria', 'level_cidadania_usoresponsavel',
        'level_cidadania_usoseguro', 'level_cidadania_usocritico', 'level_desenvolvimento_autodesenvolvimento', 'level_desenvolvimento_autoavaliacao',
        'level_desenvolvimento_compartilhamento', 'level_desenvolvimento_comunicacao', 'level_cidadania_inclusao']

      if(user.admin_country? || user.admin?)
        survey = Survey.where(type: "personal").where(active: true).first

        resp = SurveyResponse.where(:status => "Complete").where(survey_id: survey['id']).first
        fields = resp['results'].to_a

        survSecIds = []
        fields.each do |f|
          survSecIds.push(f['survey_section_id'].to_s)
        end

        columns = []
        optIds = []

        survSecIds.each do |s|
          sq = SurveyQuestion.where(:survey_section_id => BSON::ObjectId.from_string(s))
          qo = sq.pluck('question_order')
          c = sq.pluck('survey_question_description')
          sq.each do |k|
            for i in 1..k['survey_question_description'].length()
              str = "pergunta_" + k['question_order'].to_s + "_opcao_" + i.to_s
              columns.push(str)
              if(k['type'] == 'checkbox' || k['type'] == 'radio')
                qid = k['survey_question_description'][i-1]['id']
                optIds.push(qid)
              else
                optIds.push(nil)
              end
            end 
          end
        end

        rows = rows + columns

        surveyResp = SurveyResponse.where(:status => "Complete").where(survey_id: survey['id']).where(:type.exists => false)
        id = 0

        teachers_csv = CSV.open(self.link, "w", col_sep: ",", force_quotes: true, headers: true, encoding: Encoding::UTF_8) do |row_csv|
          row_csv << rows
          surveyResp.each do |sr|
            if(user.admin_country?)
              u = User.where(id: sr['user_id']).first
              if(u['country_id'] == user['country_id'])
                s = School.where(id: u['school_id']).first
                if(s['name'] != "Dummy School For Unaffiliated Users")
                  respV = []
                  responses = ResponseAnswer.where('school_id': u['school_id']).where('survey_response_id': sr['id']).where('user_id': sr['user_id']).pluck('options')

                  respOpts = responses.flatten

                  optIds.each do |oid|
                    if (respOpts.include?(oid.to_s))
                      respV.push(1)
                    else
                      respV.push(0)
                    end
                  end
                  
                  year = SurveySchedule.where(id: BSON::ObjectId.from_string(sr['survey_schedule_id'])).first

                  stagesR = []
                  st = u['stages']
                  stages.each do |stage|
                    if(st.include?(stage.to_s))
                      stagesR.push(1)
                    else
                      stagesR.push(0)
                    end
                  end

                  knowledgesR = []
                  k = u['knowledges']
                  knowledges.each do |knowledge|
                    if(k.include?(knowledge.to_s))
                      knowledgesR.push(1)
                    else
                      knowledgesR.push(0)
                    end
                  end

                  formacaoR = []
                  if(u['formation'].to_s == "false")
                    formacao.each do |ff|
                      formacaoR.push(0)
                    end
                  else
                    f = u['formation_level']
                    formacao.each do |ff|
                      if(f.include?(ff.to_s))
                        formacaoR.push(1)
                      else
                        formacaoR.push(0)
                      end
                    end
                  end
                  
                  levels = []
                  results = sr['results']
                  results.each do |r|
                    levels.push(r['value'])
                  end

                  if(year.nil?)
                    y = nil
                  else
                    y = year['name']
                  end

                  row_csv << [y, id, s.inep_code, s.country_name, s.state_name, s.province_name, s.city_name, s.affiliation_name] + stagesR + knowledgesR + [u['formation']] + formacaoR + [u['sharing']] + levels + respV
                  id = id + 1
                end
              end
            else
              u = User.where(id: sr['user_id']).first
              s = School.where(id: u['school_id']).first
              if(s['name'] != "Dummy School For Unaffiliated Users")
                respV = []
                responses = ResponseAnswer.where('school_id': u['school_id']).where('survey_response_id': sr['id']).where('user_id': sr['user_id']).pluck('options')

                respOpts = responses.flatten

                optIds.each do |oid|
                  if (respOpts.include?(oid.to_s))
                    respV.push(1)
                  else
                    respV.push(0)
                  end
                end
                
                year = SurveySchedule.where(id: BSON::ObjectId.from_string(sr['survey_schedule_id'])).first

                stagesR = []
                st = u['stages']
                stages.each do |stage|
                  if(st.include?(stage.to_s))
                    stagesR.push(1)
                  else
                    stagesR.push(0)
                  end
                end

                knowledgesR = []
                k = u['knowledges']
                knowledges.each do |knowledge|
                  if(k.include?(knowledge.to_s))
                    knowledgesR.push(1)
                  else
                    knowledgesR.push(0)
                  end
                end

                formacaoR = []
                if(u['formation'].to_s == "false")
                  formacao.each do |ff|
                    formacaoR.push(0)
                  end
                else
                  f = u['formation_level']
                  formacao.each do |ff|
                    if(f.include?(ff.to_s))
                      formacaoR.push(1)
                    else
                      formacaoR.push(0)
                    end
                  end
                end
                
                levels = []
                results = sr['results']
                results.each do |r|
                  levels.push(r['value'])
                end

                if(year.nil?)
                  y = nil
                else
                  y = year['name']
                end

                row_csv << [y, id, s.inep_code, s.country_name, s.state_name, s.province_name, s.city_name, s.affiliation_name] + stagesR + knowledgesR + [u['formation']] + formacaoR + [u['sharing']] + levels + respV
                id = id + 1
              end
            end
          end
        end
      end
    else
      render json: {status: 'ERROR', message:'User not allowed', data: params},status: '400 '
    end
  end

  def localSendEmail(user)
    if Rails.env.production? || Rails.env.staging?
      UserMailer.send_response(user, self).deliver
    else
      true
    end
  end

  def complete_proccess(user)
    self.status       = true
    self.finished_at = Time.now

    if (self.type == "school")
      export_schools_microdata(user)
    else
      export_teachers_microdata(user)
    end

    self.save
  end

  protected
  def without_callback(*args)
    self.class.skip_callback(*args)
    yield
    self.class.set_callback(*args)
  end

end
