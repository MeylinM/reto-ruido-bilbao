getwd()
#Descargar Sonómetros – mediciones (JSON)
url_mediciones <- "https://www.bilbao.eus/aytoonline/jsp/opendata/movilidad/od_sonometro_mediciones.jsp?idioma=c&formato=json"
download.file(url_mediciones, "./datos/base/mediciones.json") 

#Descargar Sonómetros – ubicación (GeoJSON)
url_ubicacion <- "https://www.bilbao.eus/aytoonline/jsp/opendata/movilidad/od_sonometro_ubicacion.jsp?idioma=c&f"
download.file(url_ubicacion, "./datos/base/ubicacion.json") 

#Descargar Tráfico Bilbao (GeoJSON)
url_trafico <- "https://www.bilbao.eus/aytoonline/srvDatasetTrafico?formato=geojson"
download.file(url_trafico, "./datos/base/trafico.json")
