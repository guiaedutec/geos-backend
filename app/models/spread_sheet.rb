class SpreadSheet
  include Mongoid::Document
  include Mongoid::Timestamps

  field :colARespId, type: Integer
  field :colBDtSubmit, type: DateTime
  field :colCStatus, type: String
  field :colDUrlInep, type: String
  field :colEUrlUser, type: String
  field :colFUrlGuid, type: String
  field :colGUrlUf, type: String
  field :colHSituacao, type: String
  field :colIFoco, type: String
  field :colJAluno, type: String
  field :colKProfessor, type: String
  field :colLEquipeGes, type: String
  field :colMFamiliar, type: String
  field :colNOutro, type: String
  field :colOOutro, type: String
  field :colPInicia, type: String
  field :colQVideo, type: String
  field :colRVideo, type: String
  field :colSVideo, type: String
  field :colTVideo, type: String
  field :colUVideo, type: String
  field :colVEscola, type: String
  field :colWUsuario, type: String
  field :colXEstado, type: String
  field :schoolName, type: String
  field :cityName, type: String
  field :stateName, type: String
  field :rating, type: Integer
  field :ratingCount, type: Integer

  def to_s
    "#{colARespId}/#{schoolName}/#{cityName}/#{stateName}/#{colCStatus}"
  end
  
  def self.populateSpreadSheet(dataToSave)
    
    dbSaveCount = 0
    
    if (dataToSave.size >= 1) then
      SpreadSheet.delete_all
    end
      
    dataToSave.each do |sub|
      SpreadSheet.create(colARespId: sub[0], colBDtSubmit: sub[1], colCStatus: sub[2], colDUrlInep: sub[3], colEUrlUser: sub[4], colFUrlGuid: sub[5], colGUrlUf: sub[6], 
        colHSituacao: sub[7], colIFoco: sub[8], colJAluno: sub[9], colKProfessor: sub[10], colLEquipeGes: sub[11], colMFamiliar: sub[12], colNOutro: sub[13], 
        colOOutro: sub[14], colPInicia: sub[15], colQVideo: sub[16], colRVideo: sub[17], colSVideo: sub[18], colTVideo: sub[19], colUVideo: sub[20], 
        colVEscola: sub[21], colWUsuario: sub[22], colXEstado: sub[23], schoolName: sub[24], cityName: sub[25], stateName: sub[26], rating:0, ratingCount:0)
      dbSaveCount = dbSaveCount + 1
    end
    
    return dbSaveCount
    
  end

  def self.ratingProject(dataToSave)
    SpreadSheet.where(:colARespId => dataToSave.at(0)).inc(:rating => dataToSave.at(1))
    SpreadSheet.where(:colARespId => dataToSave.at(0)).inc(:ratingCount => 1)
  end
  
end
