library(jsonlite)


url_trafico <- "https://www.bilbao.eus/aytoonline/srvDatasetTrafico?formato=geojson"
archivo <- "./datos/base/trafico_historico.json"

# Parámetros
horas <- 1
intervalo <- 20 * 60
iteraciones <- (horas * 60) / 10

dir.create("./datos/base", recursive = TRUE, showWarnings = FALSE)

# Cargar histórico si existe
if (file.exists(archivo)) {
  historico <- fromJSON(archivo, simplifyVector = FALSE)
} else {
  historico <- list(
    type = "FeatureCollection",
    features = list()
  )
}

for (i in 1:iteraciones) {
  
  geojson <- fromJSON(url_trafico, simplifyVector = FALSE)
  
  # Añadir las features tal cual vienen
  historico$features <- c(historico$features, geojson$features)
  
  write_json(historico, archivo, pretty = TRUE, auto_unbox = TRUE)
  
  cat(" Features añadidas:", length(geojson$features),
      "- Total acumuladas:", length(historico$features), "\n")
  
  Sys.sleep(intervalo)
}
