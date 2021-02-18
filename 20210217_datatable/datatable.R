# Demostración del funcionamiento de data.table
# de Guillermo García (gguille077 en todas las redes) para @RenRosarioArg

# machete oficial completo:
# https://raw.githubusercontent.com/rstudio/cheatsheets/master/datatable.pdf
#

# inicialización ----
for (paquete in c("data.table")) {
  if (!suppressMessages(require(paquete, character.only = T))) {
    install.packages(paquete, dependencies = T)
    suppressMessages(library(paquete, character.only = T))
  }
}
remove(paquete)
options(
  scipen = 7,
  digits = 3,
  mc.cores = parallel::detectCores()
)

# Cambia el directorio activo al lugar donde está el scritp
# solo sirve en RStudio
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Estimaciones del ministerio de agricultura sobre la producción de los cultivos
# fuente: http://datosestimaciones.magyp.gob.ar/reportes.php?reporte=Estimaciones

# Carga de nuestro primer data.table
dt <- fread("Estimaciones.csv")
class(dt)
head(dt)

# si por la razón que fuere la función con la que están trabajando devuelve un data.frame
# siempre pueden usar dt <- data.table(df)

# voy a cargar el mismo CSV, pero como data.frame
df <- read.csv("Estimaciones.csv")
head(df)
# jmmm...
df <- read.csv("Estimaciones.csv", sep = ";")
head(df)

# a primera vista, bastante parecido a un data.frame...
dt$Cultivo
unique(dt$Cultivo)

# comienzan algunas mejoras..
dt

# ahora busquemos el área de avena, desde el df
df[Cultivo == "Avena"]

# jmmm 1...
df[df$Cultivo == "Avena"]

# jmmm 2...
df[df$Cultivo == "Avena",]

# !!!!

# Vamos con lo mismo con el dt
dt[Cultivo == "Avena"]

# ahora solo la del último año
dt[Cultivo == "Avena" & Campaña == "2019/20"]

# ahora vamos a ordenar esos resultados de mayor a menor producción
dt[Cultivo == "Avena" & Campaña == "2019/20"][order(-Producción)]

# seleccionemos solo algunas columnas
dt[Cultivo == "Avena" &
     Campaña == "2019/20", c("Sup. Sembrada", "Sup. Cosechada", "Producción", "Rendimiento")]

# también se puede usar el operador de lista de data.table, .()
dt[Cultivo == "Avena" &
     Campaña == "2019/20", .(`Sup. Sembrada`, `Sup. Cosechada`, `Producción`, `Rendimiento`)]

# también podemos NO seleccionar alguna con el operador - o !
dt[Cultivo == "Avena" & Campaña == "2019/20", -c("idProvincia")]

# en el parámetro j se pueden poner expresiones también
# por ejemplo podríamos calcular el total producido a nivel nacional
dt[Cultivo == "Avena" & Campaña == "2019/20", sum(Producción)]

# o el promedio provincial
dt[Cultivo == "Avena" & Campaña == "2019/20", mean(Producción)]

# de cuántas provincias?
dt[Cultivo == "Avena" & Campaña == "2019/20", .(mean(Producción), length(Producción))]

# también podemos usar la expresión especial .N
dt[Cultivo == "Avena" & Campaña == "2019/20", .(mean(Producción), .N)]

# o agrupar
dt[Cultivo == "Avena", .(ProducciónNac = sum(Producción)), Campaña][order(Campaña)]

# y devolver ordenado
dt[Cultivo == "Avena", .(ProducciónNac = sum(Producción)), keyby = .(Campaña)]

# el j también tiene un operador especial, el :=, con el que puedo actualizar una columna
class(dt[, `Sup. Cosechada`])
dt[, `Sup. Cosechada` := as.numeric(`Sup. Cosechada`)]
class(dt[, `Sup. Cosechada`])

# o crear una nueva
dt[, Rinde := round(Producción / `Sup. Cosechada` * 1000)]

dt[ Rinde != Rendimiento, .N]
dt[ Rinde != Rendimiento]

# o actualizar un valor de algunas filas!
dt[, `Sup. Sembrada` := as.numeric(`Sup. Sembrada`)]
dt[ `Sup. Cosechada` == 0, Rinde := Producción / `Sup. Sembrada`]

dt[ Rinde != Rendimiento, .N]
dt[ Rinde != Rendimiento]