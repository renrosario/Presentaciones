# instalación y/o carga de los paquetes a usar ----
for (paquete in c("data.table", "missMDA", "visdat", "ggplot2")) {
  if (!suppressMessages(require(paquete, character.only = T))) {
    install.packages(paquete, dependencies = T)
    suppressMessages(library(paquete, character.only = T))
  }
}
remove(paquete)

# carga de datos ----
dt <-
  data.table(
    read.csv(
      "https://www.dropbox.com/s/q12gt8iuoikez8m/DNK_MaxT.csv?dl=1",
      row.names = NULL
    )
  )
# conversión del formato de fecha porque es de Excel...
dt$Date <- as.Date(dt$Date, origin = "1899-12-30")
# remuevo espacios y barras de los nombres de las estaciones meteorológicas
dt$WS_Name <- make.names(dt$WS_Name)
print(dt)

# análisis exploratorio de los datos ----
summary(dt)

# visualización de los datos faltantes así como vienen
vis_miss(dt)

# pivotear el nombre de la estación meteorológica
dp <- dcast(dt, Date ~ WS_Name, value.var = "MaxT")
print(dp)

# visualización de la versión pivoteada
vis_miss(dp)

# intento de llevar a cabo, por ejemplo, una regresión múltiple
regmul <-
  lm(AALBORG ~ ABED + BILLUND.LUFTHAVN + COPENHAGEN.KASTRUP + KARUP,
     data = dp)
summary(regmul)

# imputación con missMDA ----
# necesita los nombres de las filas
rownames(dp) <- dp$Date
dpo <- dp

# en mi experiencia, no converge si no hay al menos 3 observaciones
# removemos las columnas que no tienen al menos 3 datos
dp <-
  dp[, which(unlist(lapply(dp, function(x)
    sum(is.na(
      x
    )) < length(x) - 3))), with = F]

# calculamos las componentes principales robustas
ncomp <- estim_ncpPCA(dp[,!"Date", with = FALSE])

# corremos la imputación propiamente dicha
res.imp <-
  imputePCA(dp[,!"Date", with = FALSE], ncp = ncomp$ncp)

# preparo la salida
dp <- cbind(Date = dp$Date, data.table(res.imp$completeObs))

# visualización de la salida
vis_miss(dp)

# corro mi modelo de regresión múltiple
regmul <-
  lm(AALBORG ~ ABED + BILLUND.LUFTHAVN + COPENHAGEN.KASTRUP + KARUP,
     data = dp)
summary(regmul)

# vamos a borrar algunos datos al azar y rellenarlos para ver cómo se comparan
set.seed(678)
dp <- dpo
indices <- ceiling(runif(100, min = 1, max = nrow(dp)))
originales <- dp[indices, AALBORG]
dp[indices, AALBORG := NA]
ncomp <- estim_ncpPCA(dp[,!"Date", with = FALSE])
res.imp <-
  imputePCA(dp[,!"Date", with = FALSE], ncp = ncomp$ncp)
dp <- cbind(Date = dp$Date, data.table(res.imp$completeObs))

imputados <- dp[indices, AALBORG]
originales - imputados
salida <-
  data.table(originales = originales, imputados = imputados)

ggplot(salida, aes(x = imputados, y = originales)) +
  geom_point() +
  theme_light()
mean(abs(salida$imputados - salida$originales))
