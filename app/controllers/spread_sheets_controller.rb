class SpreadSheetsController < ApplicationController
    
  def index
    relativePath = File.dirname(__FILE__)
    @spreadSheetPopProcMsg = ""
    @invalidSpreadSheetRowsList = Array.new
    @notNullColsNumerArrayList =""
    
    begin
      
      filePath = File.expand_path("../../public/uploads/spread_sheets", relativePath)
      filePath = filePath + "/"
      
      if ((!params[:spreadsheetfilename].nil?) and (params[:spreadsheetfilename].size > 0)) then
        fileName = params[:spreadsheetfilename]
      else
        fileName = "inspirese.xlsx"
      end
      
      fileCompletePath = filePath + fileName
      populateIt = false
      
      case File.extname(fileName)
        when '.xls' then 
          file = Roo::Excel.new(fileCompletePath)
          populateIt = true
        when '.xlsx' then 
          file = Roo::Excelx.new(fileCompletePath)
          populateIt = true
        when '.csv' then 
          file = Roo::CSV.new(fileCompletePath)
          populateIt = true
        else 
          logger.error("Formato de arquivo #{File.extname(fileName)} não permitido, arquivo #{fileName}. Os tipos permitidos são xls, xlsx e csv.")
          @spreadSheetPopProcMsg = "Formato de arquivo #{File.extname(fileName)} não permitido, arquivo #{fileName}. Os tipos permitidos são xls, xlsx e csv."
          populateIt = false
      end
          
      if (populateIt) then
        rowFileIndex = file.last_row
        columnFileIndex = file.last_column - 1
        notNullColsNumerArray = [0,7,8,9,10,11,12,15,21]
        invalidSpreadSheetRows = Array.new
        invalidSpreadSheetRowsIndex = 0
        validRowFlag = false
        auxArray = Array.new
        auxArrayIndex = 0
        dataToSaveRowsQtde = 0
        dataToSaveColumnsQtde = 0
        dataToSaveRowIndex = 0
        dataToSaveColumnIndex = 0
         
        (2..rowFileIndex).each do |i|
          (0..columnFileIndex).each do |j|
            columnEmpty = verifyEmptyColumn(file.row(i)[j].to_s)
            
            if (columnEmpty) then
              
              foundRequiredColumnEmpty = false
              
              notNullColsNumerArray.each do |z|
                if (j == z) then
                  foundRequiredColumnEmpty = true
                  break
                else
                  foundRequiredColumnEmpty = false
                end
              end
                
              if (foundRequiredColumnEmpty) then
                invalidSpreadSheetRows[invalidSpreadSheetRowsIndex] = i - 1
                invalidSpreadSheetRowsIndex = invalidSpreadSheetRowsIndex + 1
                validRowFlag = false
                break
              else
                validRowFlag = true
              end
            else
              validRowFlag = true
            end
          end
          
          if (validRowFlag) then
            auxArray[auxArrayIndex] = file.row(i)
            auxArrayIndex = auxArrayIndex + 1
          end
            
          validRowFlag = false
          
        end
        
        dataToSaveRowsQtde = auxArrayIndex
        dataToSaveColumnsQtde = file.last_column + 4
        dataToSave = Array.new(dataToSaveRowsQtde){Array.new(dataToSaveColumnsQtde)}
        
        auxArray.each do |i|
          i.each do |j|
            dataToSave[dataToSaveRowIndex][dataToSaveColumnIndex] = j
            dataToSaveColumnIndex = dataToSaveColumnIndex + 1
          end
          
          inpCode = auxArray[dataToSaveRowIndex][21].to_i
          school = School.find_by(inep_code: inpCode)
          city = City.find_by(_id: school.city_id)
          state = State.find_by(_id: city.state_id)
            
          dataToSave[dataToSaveRowIndex][dataToSaveColumnIndex] = school.name
          dataToSaveColumnIndex = dataToSaveColumnIndex + 1
          
          dataToSave[dataToSaveRowIndex][dataToSaveColumnIndex] = city.name
          dataToSaveColumnIndex = dataToSaveColumnIndex + 1
          
          dataToSave[dataToSaveRowIndex][dataToSaveColumnIndex] = state.name
          
          dataToSaveColumnIndex = 0
          dataToSaveRowIndex = dataToSaveRowIndex + 1
        end
          
        spreadSheetCount = SpreadSheet.populateSpreadSheet(dataToSave)
          
        if (spreadSheetCount > 0) then
          if (spreadSheetCount == 1) then
            @spreadSheetPopProcMsg = "Foi salvo com sucesso " + spreadSheetCount.to_s + " registro da planilha no banco de dados."
          else
            @spreadSheetPopProcMsg = "Foram salvos com sucesso " + spreadSheetCount.to_s + " registros da planilha no banco de dados."
          end
        else
          @spreadSheetPopProcMsg = "Não foram salvos registros da planilha no banco de dados. Por favor, verifique se a planilha está vazia ou com colunas obrigatórias sem conteúdo."
        end
        
        @invalidSpreadSheetRowsList = invalidSpreadSheetRows
        @notNullColsNumerArrayList = notNullColsNumerArray
      end
          
    rescue IOError => exc
        logger.error("#{exc.message}\nErro ao tentar localizar o arquivo " + fileName + ". Por favor, verifique se o arquivo se encontra no diretório " + filePath + ".")
        @spreadSheetPopProcMsg = "Erro ao tentar localizar o arquivo " + fileName + ". Por favor, verifique se o arquivo se encontra no diretório " + filePath + "."
    rescue Exception => exc
        logger.error("#{exc.message}\nErro inesperado durante processamento. Por favor, contate o administrador do sistema.")
        @spreadSheetPopProcMsg = "Erro inesperado durante processamento. Por favor, contate o administrador do sistema."
    end
  end
          
  def verifyEmptyColumn(columnContent)
    columnEmpty = false
    
    if (columnContent.nil? || columnContent.strip.empty?) then
      columnEmpty = true
    end
    
    return columnEmpty
  end
    
  private :verifyEmptyColumn
  
end
