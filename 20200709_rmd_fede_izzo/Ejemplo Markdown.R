setwd("Sin Figuras/")

if (file.exists("Resultados") == FALSE) {
  dir.create("Resultados")
}


num <- c("Volkswagen Fox","Subaru XT","Peugeot 405")
renderMyDocument <- function(num) {
  rmarkdown::render("Ejemplo Rmarkdown.Rmd",
                    output_format = "html_document",
                    output_file = paste0("Resultados/Resultado del Ejemplo-",num,"-",".html"),
                    params = list(num = num))}

mapply(renderMyDocument, num)








