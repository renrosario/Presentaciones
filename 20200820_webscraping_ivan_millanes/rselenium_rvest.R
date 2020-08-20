# Cargar librerias ####
library(tidyverse)
library(RSelenium)
library(rvest)

# Setup Selenium Driver ####
# Iniciar Selenium server y browser
rD <- RSelenium::rsDriver(browser = "chrome",
                          chromever =
                            system2(command = "wmic",
                                    args = 'datafile where name="C:\\\\Program Files (x86)\\\\Google\\\\Chrome\\\\Application\\\\chrome.exe" get Version /value',
                                    stdout = TRUE,
                                    stderr = TRUE) %>%
                            stringr::str_extract(pattern = "(?<=Version=)\\d+\\.\\d+\\.\\d+\\.") %>%
                            magrittr::extract(!is.na(.)) %>%
                            stringr::str_replace_all(pattern = "\\.",
                                                     replacement = "\\\\.") %>%
                            paste0("^",  .) %>%
                            stringr::str_subset(string =
                                                  binman::list_versions(appname = "chromedriver") %>%
                                                  dplyr::last()) %>%
                            as.numeric_version() %>%
                            max() %>%
                            as.character())
# Asignar el cliente a un objeto
remDr <- rD[["client"]]

# Uso basico ####
# Usar "metodo" sin () para obtener una descripcion de lo que hace
remDr$navigate
remDr$findElement

# Algunas funciones
remDr$navigate("https://www.google.com/")
remDr$navigate("https://www.nytimes.com/")

remDr$goBack()
remDr$goForward()
remDr$refresh()
remDr$getCurrentUrl()
remDr$maxWindowSize()
remDr$getPageSource()[[1]]

remDr$close()
remDr$open()

# Trabajando con elementos

# Se necesita un conocimiento basico de HTML, CSS y/o xpath para
# encontrar los elementos.
# Por lo general, uso CSS. A veces copio y pego codigo de xpath de posts de stackoverflow
# SelectorGadget / Inspeccionar source code (F12)

# Navegar a Google
remDr$navigate("https://www.google.com/")

# Encontrar la barra de busqueda
webElem <- remDr$findElement(using = "css selector", value = ".gLFyf.gsfi")

# Resaltar para ver si el elemento fue elegido correctamente
webElem$highlightElement()

# Enviar busqueda y presionar enter
# Opcion 1
webElem$sendKeysToElement(list("the new york times"))
webElem$sendKeysToElement(list(key = "enter"))
# Opcion 2
webElem$sendKeysToElement(list("the new york times", key = "enter"))

# Volver a Google
remDr$goBack()

# Encontrar la barra de busqueda
webElem <- remDr$findElement(using = "css selector", value = ".gLFyf.gsfi")

# Buscar otra cosa
webElem$sendKeysToElement(list("finantial times"))

# Limpiar elemento
webElem$clearElement()

# Buscar y clickear
webElem <- remDr$findElement(using = "css selector", value = ".gLFyf.gsfi")
webElem$sendKeysToElement(list("the new york times", key = "enter"))
webElem <- remDr$findElement(using = "css selector", value = ".LC20lb.DKV0Md")
webElem$clickElement()

# Otras funciones
remDr$getStatus()
remDr$getTitle()
remDr$screenshot()

remDr$getWindowSize()
remDr$setWindowSize(1000,800)
remDr$getWindowPosition()
remDr$setWindowPosition(100, 100)

webElem$getElementLocation()


# Ejemplo de la Premier League ####
# Navegar a la pagina web
remDr$navigate("https://www.premierleague.com/stats/top/players/goals?se=274")
# Esperar a que la pagina cargue
Sys.sleep(4)

# Aumentar el tamaño de la ventana para encontrar elementos
remDr$maxWindowSize()

# Cerrar publicidad
closeAdd <- remDr$findElement(using = "css selector",
                              value = "#advertClose")
closeAdd$clickElement()

# Aceptar cookies
acceptCookies <- remDr$findElement(using = "css selector",
                                   value = "div[class='btn-primary cookies-notice-accept']")
acceptCookies$clickElement()

# > Obtener valores para iterar ####
# Leer el source de la pagina
source <- remDr$getPageSource()[[1]]

# Obtener topStats
list_topStats <- read_html(source) %>% 
  html_nodes(".topStatsLink") %>% 
  html_text() %>% 
  str_trim() %>% 
  str_to_title() # In this particular case

# Para hacer el ejemplo mas sencillo
list_topStats <- list_topStats[c(1, 2, 5, 8, 10, 15)]



# Obtener seasons
list_seasons <- read_html(source) %>% 
  html_nodes("ul[data-dropdown-list=FOOTBALL_COMPSEASON] > li") %>% 
  html_attr("data-option-name") %>% 
  .[-1]

# Para hacer el ejemplo mas sencillo
list_seasons <- list_seasons[c(2,3)]



# Obtener positions
list_positions <- read_html(source) %>% 
  html_nodes("ul[data-dropdown-list=Position] > li") %>% 
  html_attr("data-option-id") %>% 
  .[-1]


# > Web scraping ####

# Prealocar vector
data_topStats <- vector("list", length(list_topStats))

# Iterar sobre topStat
for (i in seq_along(list_topStats)){
  # Abrir topStat dropdown list
  DDLtopStat <- remDr$findElement(using = "css selector", 
                    value = ".dropDown.noLabel.topStatsFilterDropdown")
  DDLtopStat$clickElement()
  Sys.sleep(2)
  
  # Clickear topStat correspondiente
  ELEMtopStat <- remDr$findElement(using = "link text", 
                                   value = list_topStats[[i]])
  ELEMtopStat$clickElement()
  Sys.sleep(2)
  
  # Prealocar vector
  data_seasons <- vector("list", length(list_seasons))
  
  # Iterar sobre seasons
  for (j in seq_along(list_seasons)){
    # Abrir seasons dropdown list
    DDLseason <- remDr$findElement(using = "css selector", 
                                   value = ".current[data-dropdown-current=FOOTBALL_COMPSEASON]")
    DDLseason$clickElement()
    Sys.sleep(2)
    
    # Clickear season correspondiente
    ELEMseason <- remDr$findElement(using = "css selector",
                                    value = str_c("ul[data-dropdown-list=FOOTBALL_COMPSEASON] > li[data-option-name='", list_seasons[[j]], "']"))
    ELEMseason$clickElement()
    Sys.sleep(2)
    
    # Cerrar publicidad
    closeAdd <- remDr$findElement(using = "css selector",
                                  value = "#advertClose")
    closeAdd$clickElement()
    
    # Prealocar vector
    data_positions <- vector("list", length(list_positions))
    
    # Iterar sobre position
    for (k in seq_along(list_positions)){
      # Abrir positions dropdown list
      DDLposition <- remDr$findElement(using = "css selector", 
                                       value = ".current[data-dropdown-current=Position]")
      DDLposition$clickElement()
      Sys.sleep(2)
      
      # Clickear position correspondiente
      ELEMposition <- remDr$findElement(using = "css selector", 
                                        value = str_c("ul[data-dropdown-list=Position] > li[data-option-id='", list_positions[[k]], "']"))
      ELEMposition$clickElement()
      Sys.sleep(2)
      
      # Checkear que haya una tabla para scrapear. Si no hay, ir a la siguiente position
      check_table <- remDr$getPageSource()[[1]] %>% 
        read_html() %>% 
        html_node(".statsTableContainer") %>% 
        html_text()
      
      if(check_table == "No stats are available for your search") next
      
      # Rellenar el elemento de la position correspondiente (primera pagina)
      data_positions[[k]] <- remDr$getPageSource()[[1]] %>% 
        read_html() %>% 
        html_table() %>% 
        .[[1]] %>% 
        as_tibble() %>% 
        # Miles estan en character ("1,000"), da problema cuando se une con integer (1:999)
        mutate(Stat = as.character(Stat) %>% 
                 parse_number())
      
      # Obtener tablas por todas las paginas
      btnNextExists <- remDr$getPageSource()[[1]] %>% 
        read_html() %>% 
        html_node(".paginationNextContainer.inactive") %>% 
        html_text() %>% 
        is.na()
      
      # Mientras haya un boton de Siguiente
      while (btnNextExists){
        # Clickear "Siguiente"
        btnNext <- remDr$findElement(using = "css selector",
                                     value = ".paginationNextContainer")
        btnNext$clickElement()
        Sys.sleep(2)
        
        # Obtener la tabla de la nueva pagina
        table_n <- remDr$getPageSource()[[1]] %>% 
          read_html() %>% 
          html_table() %>% 
          .[[1]] %>% 
          as_tibble() %>% 
          mutate(Stat = as.character(Stat) %>% 
                   parse_number())  
        
        # Rowbind la tabla existente con la nueva tabla
        data_positions[[k]] <- bind_rows(data_positions[[k]], table_n)
        
        # Actualizar el valor que indica si hay un boton de "Siguiente"
        btnNextExists <- remDr$getPageSource()[[1]] %>% 
          read_html() %>% 
          html_node(".paginationNextContainer.inactive") %>% 
          html_text() %>% 
          is.na()
        
        Sys.sleep(1)
      }
      
      # Data wrangling
      data_positions[[k]] <- data_positions[[k]] %>% 
        rename(!!list_topStats[[i]] := Stat) %>% 
        mutate(Position = list_positions[[k]])
      
      # Ir arriba de todo en la pagina web para seleccionar la siguiente posicion
      goTop <- remDr$findElement("css", "body")
      goTop$sendKeysToElement(list(key = "home"))
      Sys.sleep(3)
    }
    
    # Rowbind positions dataset
    data_positions <- reduce(data_positions, bind_rows)
    
    # Rellenar la season season correspondiente
    data_seasons[[j]] <- data_positions %>% 
      mutate(Season = list_seasons[[j]])
    
  }
  
  # Rowbind seasons dataset
  data_seasons <- reduce(data_seasons, bind_rows)
  
  # Rellenar topStat correspondiente
  data_topStats[[i]] <- data_seasons
    
}

# > Data wrangling ####
dataset <- data_topStats %>% 
  # Remover columna Rank
  map(function(x) select(x, -Rank)) %>% 
  # Reordenar columnas
  map(function(x) select(x, Season, Position, Club, Player, Nationality, everything())) %>%
  # Full join (porque no necesariamente todos los jugadores tienen todas las stats)
  reduce(full_join, by = c("Season", "Position", "Club", "Player", "Nationality")) %>% 
  # Reemplazar NA con 0 en columnas numericas
  mutate(across(where(is.numeric), replace_na, replace = 0))


# Comentarios ####

#   Cuidado al agregar topStats al loop. 
# El filtro position esta escondido para algunos topStats (Clean Sheets) 


# parallel Framework ####
library(tidyverse)
library(parallel)

# Definir funcion para detener Selenium en cada core
close_rselenium <- function(){
  clusterEvalQ(clust, {
    remDr$close()
    rD$server$stop()
  })
  system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)
}

# Numero de cores
detectCores()
clust <- makeCluster(4)

# Listar puertos
ports = list(4567L, 4444L, 4445L, 5555L)

# Abrir Selenium en cada core, usando un core por puerto
clusterApply(clust, ports, function(x){
  library(tidyverse)
  library(RSelenium)
  library(rvest)
  rD <<- RSelenium::rsDriver(browser = "chrome",
                             chromever =
                               system2(command = "wmic",
                                       args = 'datafile where name="C:\\\\Program Files (x86)\\\\Google\\\\Chrome\\\\Application\\\\chrome.exe" get Version /value',
                                       stdout = TRUE,
                                       stderr = TRUE) %>%
                               stringr::str_extract(pattern = "(?<=Version=)\\d+\\.\\d+\\.\\d+\\.") %>%
                               magrittr::extract(!is.na(.)) %>%
                               stringr::str_replace_all(pattern = "\\.",
                                                        replacement = "\\\\.") %>%
                               paste0("^",  .) %>%
                               stringr::str_subset(string =
                                                     binman::list_versions(appname = "chromedriver") %>%
                                                     dplyr::last()) %>%
                               as.numeric_version() %>%
                               max() %>%
                               as.character(),
                             port = x)
  remDr <<- rD[["client"]]
})

# Listar elementos para iterar con parallel processing
pgs <- list("https://www.google.com",
            "https://www.nytimes.com",
            "https://www.ft.com")

# Definir la iteracion, en este caso, navegar a la pagina web
parLapply(clust, pgs, function(x) {
  remDr$navigate(x)
})

# Cerrar Selenium en cada core
close_rselenium()

# Detener el cluster
stopCluster(clust)

