  #PAQUETES A USAR
  library(readxl)
  library(dplyr)
  library(devtools)
  library(stringr) 
  library(writexl)
  
  # CREACION DE LAS BASES MENSUALES A ENVIAR POR OPERADORA PARA TRABAJAR 
  #EN EL MES M1.
  
  # SE TOMAN COMO INPUT LAS BASES MENSUALES RECIBIDAS POR OPERADORA (MES M0 = M1-1),
  #SE CREA LA BASE UNIDA DEL MES M0, SE SELECCIONAN LOS CASOS PENDIENTES
  #Y SE CREA UN ARCHIVO PARA CADA OPERADORA A TRABAJAR EN EL MES M1

  # FIJO VARIABLES
  PERIODO_M0 = "1907"
  PERIODO_M1 = "1908"
  
  # LECTURA BASES RECIBIDAS MES M0
  setwd(paste0("C:/Users/Ivan.Millanes/OneDrive - OZ Digital Consulting/Desktop/Combinando Excel y R/Tarea 2/Bases Mensuales Individuales/Bases Recibidas/", PERIODO_M0, "/"))
  archivos <- list.files(pattern = '*.xlsx')
  nombres <- str_sub(archivos, end = -6)
  
    # AL USAR cell_cols(), SE PUEDE DEJAR AL FINAL UNA COLUMNA DE OBSERVACIONES
    #PARA QUE LAS OPERADORAS COMPLETEN, LA CUAL NO AFECTARA NUESTRA BASE DE DATOS
  for (i in 1:length(archivos)) {
    assign(nombres[i], read_excel(archivos[i], range = cell_cols("A:Q")))
  }
  dfs = sapply(.GlobalEnv, is.data.frame) 
  RET = do.call(rbind, mget(names(dfs)[dfs]))
  rm(list=setdiff(ls(), c("RET", "PERIODO_M0", "PERIODO_M1")))
  
  # CREACION BASE MENSUAL UNIDA
    #ELIMINO FILAS SIN NRO_GESTION (PUEDE PASAR QUE LA PRIMER COLUMNA, COMO SE COMPLETA
    #CON EL NOMBRE DE QUIEN CARGA EL DATO, SE COMPLETE DE MAS)
  RET = filter(RET, !is.na(RET$NRO_GESTION))
    #DOY FORMATO FECHA A LAS FECHAS
  RET$FECHA_CREACION_CONTACTO = as.Date(RET$FECHA_CREACION_CONTACTO)
  RET$FECHA_INICIO = as.Date(RET$FECHA_INICIO)
  RET$FECHA_CIERRE = as.Date(RET$FECHA_CIERRE)
  
  # GUARDO LA BASE MENSUAL UNIDA
  setwd(paste0("C:/Users/Ivan.Millanes/OneDrive - OZ Digital Consulting/Desktop/Combinando Excel y R/Tarea 2/Bases Mensuales Unidas/", PERIODO_M0, "/"))
  write_xlsx(RET, "RET.xlsx")
  
  
  #CREO LAS BASES MENSUALES MES M1
  
  dev_mode(on = TRUE)
  #Es necesario instalar esta version de openxlsx
  #install_github(repo = "tkunstek/openxlsx")
  library(openxlsx)
  
  RET$OPERADORA = as.factor(RET$OPERADORA)
  
  #ME QUEDO CON LAS GESTIONES PENDIENTES
  PEND = filter(RET, is.na(STATUS_CIERRE))
  
  for ( i in levels(PEND$OPERADORA) ) {
    
    PLANILLA = filter(PEND, OPERADORA == i)
    
    # Create workbook
    wb = createWorkbook()
    
    # Add worksheet "Planilla" to the workbook
    addWorksheet(wb, "Planilla")
    
    # Ancho de Columnas
    setColWidths(wb, "Planilla", cols = c(1:19), 
                 widths = c(11.43,13.57,10.00,27.14,
                            12.86,33.57,15.71,13.57,33.57,
                            8.57,15.00,24.29,24.29,24.29,
                            13.00,11.43,31.43))
    
    # Add Planilla dataframe to the sheet "Planilla"
    writeData(wb, sheet = "Planilla", x = PLANILLA, startCol = 1)
    
    # Add worksheet "Drop-down values" to the workbook
    addWorksheet(wb, "Categorias")
    
    # Create drop-down values dataframe
    STATUS = data.frame("STATUS_INICIO" = c("NO CORRESPONDE DERIVACION", 
                                            "NO RETENCION", 
                                            "NO SE PUDO ESTABLECER CONTACTO",
                                            "RETENCION",
                                            "NRO INHABILITADO o ERRONEO",
                                            "PENDIENTE NO CONTACTADO",
                                            "PENDIENTE CONTACTADO",
                                            "DUPLICADO"))
    
    FDP = data.frame("FORMAdePAGO" = c("CBU", "TC", "PGF", "RCE"))
    
    PCT_BONIF = data.frame("PCT" = c("0%", "5%", "10%", "15%", "20%", "25%", "30%", "-5%", "-10%", "-15%", "-20%", "-25%"))
    
    SI_NO = data.frame("SI_NO" = c("SI", "NO"))
    
    NO_RET_GRAV = data.frame("NO_RET_GRAV" = c("EMPLEO NO REGISTRADO",
                                               "CUENTA PROPIA - COMERCIANTE",
                                               "CUENTA PROPIA - PROFESIONAL",
                                               "CUENTA PROPIA - ESTATAL",
                                               "CUENTA PROPIA - OFICIO",
                                               "SIN TRABAJO/PAGA TERCERO",
                                               "NO INFORMA/NO CONTESTA"))
    
    # Add drop-down values dataframe to the sheet "Drop-down values"
    writeData(wb, sheet = "Categorias", x = STATUS, startCol = 1)
    writeData(wb, sheet = "Categorias", x = FDP, startCol = 2)
    writeData(wb, sheet = "Categorias", x = PCT_BONIF, startCol = 3)
    writeData(wb, sheet = "Categorias", x = SI_NO, startCol = 4)
    writeData(wb, sheet = "Categorias", x = NO_RET_GRAV, startCol = 5)
    
    # Add drop-downs to the column Gender on the worksheet "Planilla"
    dataValidation(wb, "Planilla", col = 6, rows = 2:800, type = "list", value = 
                     "'Categorias'!$A$2:$A$9")
    dataValidation(wb, "Planilla", col = 9, rows = 2:800, type = "list", value = 
                     "'Categorias'!$A$2:$A$9")
    dataValidation(wb, "Planilla", col = 15, rows = 2:800, type = "list", value = 
                     "'Categorias'!$B$2:$B$5")
    dataValidation(wb, "Planilla", col = 12, rows = 2:800, type = "list", value = 
                     "'Categorias'!$C$2:$C$13")
    dataValidation(wb, "Planilla", col = 13, rows = 2:800, type = "list", value = 
                     "'Categorias'!$C$2:$C$13")
    dataValidation(wb, "Planilla", col = 14, rows = 2:800, type = "list", value = 
                     "'Categorias'!$C$2:$C$13")
    dataValidation(wb, "Planilla", col = 7, rows = 2:800, type = "list", value = 
                     "'Categorias'!$D$2:$D$3")
    dataValidation(wb, "Planilla", col = 11, rows = 2:800, type = "list", value = 
                     "'Categorias'!$D$2:$D$3")
    dataValidation(wb, "Planilla", col = 17, rows = 2:800, type = "list", value = 
                     "'Categorias'!$E$2:$E$8")
    
    # Save workbook
    setwd(paste0("C:/Users/Ivan.Millanes/OneDrive - OZ Digital Consulting/Desktop/Combinando Excel y R/Tarea 2/Bases Mensuales Individuales/Bases a Enviar/", PERIODO_M1, "/"))
    saveWorkbook(wb, paste0("RET ", PERIODO_M1," ", i, ".xlsx"), overwrite = TRUE)
    
  }
  
  dev_mode(on = FALSE)
  
