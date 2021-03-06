# instalaci�n y/o carga de los paquetes a usar ----
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
# conversi�n del formato de fecha porque es de Excel...
dt$Date <- as.Date(dt$Date, origin = "1899-12-30")
# remuevo espacios y barras de los nombres de las estaciones meteorol�gicas
dt$WS_Name <- make.names(dt$WS_Name)
print(dt)

# an�lisis exploratorio de los datos ----
summary(dt)

# visualizaci�n de los datos faltantes as� como vienen
vis_miss(dt)

# pivotear el nombre de la estaci�n meteorol�gica
dp <- dcast(dt, Date ~ WS_Name, value.var = "MaxT")
print(dp)

# visualizaci�n de la versi�n pivoteada
vis_miss(dp)

# intento de llevar a cabo, por ejemplo, una regresi�n m�ltiple
regmul <-
  lm(AALBORG ~ ABED + BILLUND.LUFTHAVN + COPENHAGEN.KASTRUP + KARUP,
     data = dp)
summary(regmul)

# imputaci�n con missMDA ----
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

# corremos la imputaci�n propiamente dicha
res.imp <-
  imputePCA(dp[,!"Date", with = FALSE], ncp = ncomp$ncp)

# preparo la salida
dp <- cbind(Date = dp$Date, data.table(res.imp$completeObs))

# visualizaci�n de la salida
vis_miss(dp)

# corro mi modelo de regresi�n m�ltiple
regmul <-
  lm(AALBORG ~ ABED + BILLUND.LUFTHAVN + COPENHAGEN.KASTRUP + KARUP,
     data = dp)
summary(regmul)

# vamos a borrar algunos datos al azar y rellenarlos para ver c�mo se comparan
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
