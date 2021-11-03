# encoding: utf-8
require 'net/http'
require 'json'
require 'spreadsheet'

module BRPopulate
  CAPITAL_CITIES = [
    "Aracaju",
    "Belo Horizonte",
    "Belém",
    "Boa Vista",
    "Brasília",
    "Cuiabá",
    "Campo Grande",
    "Curitiba",
    "Florianópolis",
    "Fortaleza",
    "Goiânia",
    "João Pessoa",
    "Macapá",
    "Maceió",
    "Manaus",
    "Natal",
    "Palmas",
    "Porto Alegre",
    "Porto Velho",
    "Recife",
    "Rio Branco",
    "Rio de Janeiro",
    "Salvador",
    "São Luís",
    "São Paulo",
    "Teresina",
    "Vitória"
  ]

  def self.states
    http = Net::HTTP.new('raw.githubusercontent.com', 443); http.use_ssl = true
    JSON.parse http.get('/celsodantas/br_populate/master/states.json').body
  end


  def self.capital?(city_name)
    CAPITAL_CITIES.include?(city_name)
  end

  def self.populate
    if State.count.zero?
      states.each do |state|
        region_obj = Region.find_or_create_by(name: state["region"])
        state_obj = State.new(acronym: state["acronym"], name: state["name"], region: region_obj)
        state_obj.save
      end
    end

    file_path = Rails.root.join('spec', 'fixtures', 'ibge_cities.csv')
    CSV.foreach(file_path).with_index do |row, i|
      next if i.zero?
      c = City.new
      c.state = State.find_by name: row[1]
      c.ibge_code = row[7]
      c.name = row[8]
      c.capital = capital?(c.name)
      c.save
    end
  end
end

if City.count.zero?
  BRPopulate.populate
end

if School.count.zero?
  Rake::Task['schools:import'].invoke
end

if User.count.zero?
  user = User.create(name: 'Stefano Diem Benatti', email: 'stefano@heavenstudio.com.br', password: '12345678', city: City.first)
end

if SurveySection.blank?
  school_details = SurveySection.create name: 'Informações da Escola', position: 0, description: 'Informações da Escola'
  school_details.add_questions [144, 15]

  vision = SurveySection.create name: 'Nível Visão', position: 1, description: 'Visão: refere-se ao quanto acredita-se que a tecnologia tem o potencial de impactar positivamente as escolas, promovendo um ensino de qualidade e uma gestão escolar eficaz. Engloba, ainda, as maneiras em que tal crença se reflete em estratégias e políticas planejadas para que as escolas atinjam seus objetivos.'
  vision.add_questions [126, 127, 128, 129, 130, 131]

  competence = SurveySection.create name: 'Nível Competência', position: 2, description: 'Competências: É a dimensão que indica as habilidades e competências que diferentes atores precisam ter para o uso potencializado das tecnologias na educação. Inclui as habilidades de professores (seu conhecimento de TIC; as capacitações que recebem para isso; as formas em que utilizam TIC em suas práticas pedagógicas; a habilidade em orientar o uso de TIC por alunos; sua capacidade de desenvolver novos conteúdos digitais) e de diretores e coordenadores (sua habilidade de utilizar as TIC para melhorar sua gestão escolar e apoiar professores e alunos a utilizarem melhor as TIC).'
  competence.add_questions [132, 133, 134, 135, 136, 138]

  resource = SurveySection.create name: 'Nível Recursos', position: 3, description: 'Conteúdos e Recursos Digitais: Refere-se ao acesso e uso de programas, aplicativos e conteúdos digitais usados na instituição escolar, que incluem, por exemplo, material de aprendizado digital, programas específicos para o ensino de certas disciplinas, jogos ou vídeos educacionais, assim como softwares e aplicativos que facilitam a gestão educacional'
  resource.add_questions [139, 140, 142, 141, 143]

  infrastructure = SurveySection.create name: 'Nível Infraestrutura', position: 4, description: 'Infraestrutura. A disponibilidade e qualidade de computadores e outros equipamentos, além do acesso e qualidade da conexão com a internet. Isso inclui a gestão e disponibilidade de ferramentas como computadores, notebooks, tablets, conexões com cabo e sem fio, servidores e serviços de armazenagem na nuvem'
  infrastructure.add_questions [40, 54, 106, 41, 39]
end
