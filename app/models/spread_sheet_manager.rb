class SpreadSheetManager
  include ActiveModel::Validations
  attr_accessor :name,:email,:phone,:line, :t_error

  validates :name, presence: { message: "Nome do diretor é obrigatório/inválido" }
  validates :email, presence: { message: "Email é obrigatório" }
  validates :phone, presence: { message: "Telefone é obrigatório/inválido" }
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :message => "Email inválido"

  HUMANIZED_ATTRIBUTES = {
    :name => "Nome do diretor",
    :email => "Email",
    :phone => "Telefone",
    :line => "",
    :t_error => ""
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

end
