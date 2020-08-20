library(rvest)
library(stringr)
library(hash)

#Elegir carpeta para guardar el csv
output = "lista_deptos.csv"

# Esta tiene que ser la pág principal de resultado de la búsqueda
url <- "https://inmuebles.lacapital.com.ar/inmuebles/busqueda?csrfmiddlewaretoken=zb8k4t9H0BV2p47MYW1Frwp743wbOZ1E&q=&operacion=alquiler&inmueble=departamento&dormitorios=&banios=&precio=&m2_totales=&cliente=&localidad=rosario&zona=&cocheras=&duenio=&apto_credito="
busqueda <- read_html(url)

#Aca contamos el número de pags con resultados y agarramos la última
ultimapag <- function(html){
  
  pags <- html %>% 
    # El '.' indica la clase
    html_nodes('.click') %>% 
    # Extraer el texto como una lista
    html_text()                   
  
  # El penúltimo número es el total de páginas
  pags[(length(pags)-1)] %>%            
    # Tomar el texto
    unname() %>%                                     
    # Convertir a número
    as.numeric()                                     
}

npags <- ultimapag(busqueda)

#VECTOR CON LAS N PÁGINAS  
listapags <- str_c(url, '&page=', 1:npags)

#Vector vacío donde vamos a poner las publicaciones
pubs <- list()

#Iteración para crear la lista de publicaciones
for (i in 1:length(listapags)){
  artic <- read_html(listapags[[i]])
  
  #Obtenemos el código html que contiene el nombre del producto
  dpto_html <- html_nodes(artic,"article.propiedad a")
  dpto_texto <- html_attr(dpto_html,"href")
  
  publicaciones <- str_c("https://inmuebles.lacapital.com.ar/", dpto_texto)
  pubs <- append(pubs,publicaciones)
}

listadptos <- data.frame(id=numeric(),
                         link=character(),
                         supcub=numeric(),
                         suptot=numeric(),
                         dormitorios=numeric(),
                         baños=numeric(),
                         cocheras=numeric(),
                         precio=numeric(),
                         longmap=character(),
                         latmap=character(),
                         stringsAsFactors=FALSE)

total = length(pubs)

#sacar datos de la lista de links por dpto
for (i in 1:total){
  tryCatch({
    page <- read_html(pubs[[i]])
    
    #SACAR INFO PRINCIPAL
    # Sup cubierta
    supcub_html <- html_nodes(page,"div.sc p")
    supcub_texto <- html_text(supcub_html)
    supcub_texto_trim  <- str_trim(supcub_texto)
    superficie_cubierta <- str_remove(supcub_texto_trim, "m2")
    
    # Sup cubierta
    suptot_html <- html_nodes(page,"div.st p")
    suptot_texto <- html_text(suptot_html)
    suptot_texto_trim  <- str_trim(suptot_texto)
    superficie_total <- str_remove(suptot_texto_trim, "m2")
    
    # Dormitorios
    dorm_html <- html_nodes(page,"div.do p")
    dorm_texto <- html_text(dorm_html)
    dormitorios <- str_trim(dorm_texto)
    
    # Baños
    baño_html <- html_nodes(page,"div.ba p")
    baño_texto <- html_text(baño_html)
    baños <- str_trim(baño_texto)
    
    # Cocheras
    coche_html <- html_nodes(page,"div.ba p")
    coche_texto <- html_text(coche_html)
    cocheras <- str_trim(coche_texto)
    
    # Precio
    precio_html <- html_nodes(page,"div.pr p")
    precio_texto <- html_text(precio_html)
    precio <- if (!identical(precio_texto, character(0))){
      str_extract(precio_texto, "[0-9]+")
    } else {
      ""
    }
    
    # Obtener info del mapa
    mapa_html <- html_nodes(page,"section.mapa.nopad div.container")
    mapa_texto <- html_text(mapa_html)
    
    # Longitud
    map_long <- str_extract(mapa_texto, "map_long[:space:]=[:space:].+?;")
    longitud_mapa <- if (!identical(map_long, character(0))){
      str_extract(map_long, "[\\-0-9]+.*[0-9]+")
    } else {
      ""
    }
    
    # Latitud
    map_lat <- str_extract(mapa_texto, "map_lat[:space:]=[:space:].+?;")
    latitud_mapa <- if (!identical(map_lat, character(0))){
      str_extract(map_lat, "[\\-0-9]+.*[0-9]+")
    } else {
      ""
    }
    
    listadptos[i,"id"] <- i
    listadptos[i,"link"] <- pubs[[i]]
    listadptos[i,"supcub"] <- superficie_cubierta
    listadptos[i,"suptot"] <- superficie_total
    listadptos[i,"dormitorios"] <- dormitorios
    listadptos[i,"baños"] <- baños
    listadptos[i,"cocheras"] <- cocheras
    listadptos[i,"precio"] <- precio
    listadptos[i,"longmap"] <- longitud_mapa
    listadptos[i,"latmap"] <- latitud_mapa
  }, error=function(e){cat("ERROR in row:", i, conditionMessage(e), "\n")})
}

write.csv(listadptos, file=output)