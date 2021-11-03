json.array!(@spread_sheets) do |spread_sheet|
  json.extract! spread_sheet, :colARespId, :colBDtSubmit, :colCStatus, :colDUrlInep, :colEUrlUser, :colFUrlGuid, :colGUrlUf, :colHSituacao, :colIFoco, :colJAluno, :colKProfessor, :colLEquipeGes, :colMFamiliar, :colNOutro, :colOOutro, :colPInicia, :colQVideo, :colRVideo, :colSVideo, :colTVideo, :colUVideo, :colVEscola, :colWUsuario, :colXEstado, :rating
  json.url spread_sheet_url(spread_sheet, format: :json)
end
