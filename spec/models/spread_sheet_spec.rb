require 'rails_helper'

RSpec.describe SpreadSheet, type: :model do
  context 'Fields' do
    it { is_expected.to have_field(:colARespId).of_type(Integer) }
    it { is_expected.to have_field(:colBDtSubmit).of_type(DateTime) }
    it { is_expected.to have_field(:colCStatus).of_type(String) }
    it { is_expected.to have_field(:colDUrlInep).of_type(String) }
    it { is_expected.to have_field(:colEUrlUser).of_type(String) }
    it { is_expected.to have_field(:colFUrlGuid).of_type(String) }
    it { is_expected.to have_field(:colGUrlUf).of_type(String) }
    it { is_expected.to have_field(:colHSituacao).of_type(String) }
    it { is_expected.to have_field(:colIFoco).of_type(String) }
    it { is_expected.to have_field(:colJAluno).of_type(String) }
    it { is_expected.to have_field(:colKProfessor).of_type(String) }
    it { is_expected.to have_field(:colLEquipeGes).of_type(String) }
    it { is_expected.to have_field(:colMFamiliar).of_type(String) }
    it { is_expected.to have_field(:colNOutro).of_type(String) }
    it { is_expected.to have_field(:colOOutro).of_type(String) }
    it { is_expected.to have_field(:colPInicia).of_type(String) }
    it { is_expected.to have_field(:colQVideo).of_type(String) }
    it { is_expected.to have_field(:colRVideo).of_type(String) }
    it { is_expected.to have_field(:colSVideo).of_type(String) }
    it { is_expected.to have_field(:colTVideo).of_type(String) }
    it { is_expected.to have_field(:colUVideo).of_type(String) }
    it { is_expected.to have_field(:colVEscola).of_type(String) }
    it { is_expected.to have_field(:colWUsuario).of_type(String) }
    it { is_expected.to have_field(:colXEstado).of_type(String) }
    it { is_expected.to have_field(:schoolName).of_type(String) }
    it { is_expected.to have_field(:cityName).of_type(String) }
    it { is_expected.to have_field(:stateName).of_type(String) }
  end

  describe '::populateSpreadSheet' do
    spreadSheetRegCountSuccessful = 10
    spreadSheetRegCountUnsuccessful = 0
    relativePath = File.dirname(__FILE__)
    filePath = File.expand_path("../../public/uploads/test_spread_sheets", relativePath)
    filePath = filePath + "/"
    fileName = "inspirese.xlsx"
    fileCompletePath = filePath + fileName
    file = Roo::Excelx.new(fileCompletePath)
    
    rowSize = file.last_row - 1
    columnSize = file.last_column + 4

    dataToSave = Array.new(rowSize){Array.new(columnSize)}

    (2..file.last_row).each do |i|
      tempArrayCount = i - 2
      (0..file.last_column).each do |j|
        dataToSave[tempArrayCount][j] = file.row(i)[j]
      end
      
      dataToSave[tempArrayCount][file.last_column] = "Escola Estadual de Testes"
      dataToSave[tempArrayCount][file.last_column + 1] = "Cidade de Testes"
      dataToSave[tempArrayCount][file.last_column + 2] = "Estado de Testes"
    end
    
    it 'populate spread sheet if it all right' do
      expect(described_class.populateSpreadSheet(dataToSave)).to eq spreadSheetRegCountSuccessful
    end
    
    emptyArray = Array.new(0){Array.new(0)}
    
    it 'do not populate spread sheet if it not all right' do
      expect(described_class.populateSpreadSheet(emptyArray)).to eq spreadSheetRegCountUnsuccessful
    end
  end
end
