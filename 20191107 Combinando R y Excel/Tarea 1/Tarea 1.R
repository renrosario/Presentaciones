#Paquetes a utilizar
library(readxl)
library(dplyr)
library(writexl)

PERIODO = "1902"

RUTA = "C:/Users/Ivan.Millanes/OneDrive - OZ Digital Consulting/Desktop/Combinando Excel y R/Tarea 1/"

#Lectura de la Base del Mes
Prod <- read_excel(paste0(RUTA, "Bases para Envio/Prod ",PERIODO,".xlsx"))

#Separo la Base de acuerdo al Segmento
Prod_S1 = filter(Prod, !(Prod$`Producto Plan ID` %in% c(43,44)))
Prod_S2 = filter(Prod, Prod$`Producto Plan ID` %in% c(43,44))

#Defino la RUTA en la que se crean los archivos de Excel
setwd(paste0(RUTA, "Envios/Prod ", PERIODO))

#Genero los archivos
split <- split(Prod_S1, Prod_S1$`Gerente Zonal`) 
lapply(names(split), function(x){write_xlsx(split[[x]], path = paste0(x, " - S1.xlsx"))})

split <- split(Prod_S2, Prod_S2$`Gerente Zonal`) 
lapply(names(split), function(x){write_xlsx(split[[x]], path = paste0(x, " - S2.xlsx"))})
