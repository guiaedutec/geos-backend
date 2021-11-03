class SpreadSheetSchool
  include ActiveModel::Validations

  attr_accessor :inep_code,:name,:staff_count,:student_diurnal_count,:student_vespertine_count,:student_nocturnal_count,:student_full_count,:kindergarten,:elementary_1,:elementary_2,:highschool,:technical,:adult,:location_type,:regional,:observations,:city,:state,:type, :t_error, :line, :manager, :school

  validate :school_store_validation

  validates :inep_code, presence: { message: "Código do Inep é obrigatório/inválido" }
  validates :name , presence: { message: "Nome da escola é obrigatório/inválido" }
  validates :staff_count, presence: { message: "N. de professores é obrigatório/inválido" }, numericality: { message: "N. de professores não é um número" }
  validates :student_diurnal_count , presence: { message: "N. de alunos matutino é obrigatório/inválido" }, numericality: { message: "N. de alunos matutino não é um número" }
  validates :student_vespertine_count , presence: { message: "N. de alunos verspertino é obrigatório/inválido" },numericality: { message: "N. de alunos verspertino não é um número" }
  validates :student_nocturnal_count, presence: { message: "N. de alunos noturno é obrigatório/inválido" }, numericality: { message: "N. de alunos noturno não é um número" }
  validates :student_full_count, presence: { message: "N. de alunos integral é obrigatório/inválido" }, numericality: { message: "N. de alunos integral não é um número" }
  validates :kindergarten, presence: { message: "Infantil é obrigatório/inválido" }
  validates :elementary_1, presence: { message: "Fundamental I é obrigatório/inválido" }
  validates :elementary_2, presence: { message: "Fundamental II é obrigatório/inválido" }
  validates :highschool, presence: { message: "Ensino Médio é obrigatório/inválido" }
  validates :technical, presence: { message: "Ensino Médio Técnico é obrigatório/inválido" }
  validates :adult , presence: { message: "EJA é obrigatório/inválido" }
  validates :location_type , presence: { message: "Tipo de Localização é obrigatório/inválido" }
  validates :regional , presence: { message: "Regional é obrigatório/inválido" }
  validates :observations , presence: { message: "Observação é obrigatório/inválido" }
  validates :city , presence: { message: "Cidade é obrigatório/inválido" }
  validates :state , presence: { message: "Estado é obrigatório/inválido" }
  validates :type , presence: { message: "Tipo é obrigatório/inválido" }
  validates :manager , presence: { message: "Email do diretor é obrigatório/inválido" }


  HUMANIZED_ATTRIBUTES = {
    :inep_code => "Código Inep",
    :name => "Nome da escola",
    :staff_count => "N. de professores",
    :student_diurnal_count => "N. de alunos matutino",
    :student_vespertine_count => "N. de alunos verspertino",
    :student_nocturnal_count => "N. de alunos noturno",
    :student_full_count => "N. de alunos integral",
    :kindergarten => "Infantil",
    :elementary_1 => "Fundamental I",
    :elementary_2 => "Fundamental II",
    :highschool => "Ensino Médio",
    :technical => "Ensino Médio Técnico",
    :adult => "EJA",
    :location_type => "Tipo de Localização",
    :regional => "Regional",
    :observations => "Observação",
    :city => "Cidade",
    :state => "Estado",
    :type => "Tipo",
    :line => "",
    :t_error => "",
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def school_store_validation
    if inep_code
      ret = School.where(:inep_code => inep_code).first
      if not ret
        if school.valid? == false
          school.errors.full_messages.each do |msg|
            errors[:base] << "#{msg}"
          end
        end
      end
    end
  end
end