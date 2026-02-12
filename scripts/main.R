# ==============================================================================
# CONFIGURACIÓN INICIAL
# ==============================================================================
getwd()
# 1. Cargar funciones de utilidad
source("./scripts/utils.R")

# 2. Definir las librerías necesarias para el reto
mis_paquetes <- c(
  "httr2",      # Descarga de APIs 
  "jsonlite",   # Lectura de JSON 
  "tidyverse",  # Manipulación y visualización (dplyr, ggplot2, tidyr) 
  "lubridate",  # Gestión de fechas y horas 
  "sf",         # Datos geográficos (GeoJSON) 
  "leaflet"     # Mapas interactivos
)

# 3. Descargar las librerias que nos hacen falta
cargar_librerias(mis_paquetes)

# ==============================================================================
# LIMPIAR DATOS SONOMETRO MEDICIONES
# ==============================================================================

#1. Descargar y guardar el archivo
descargar_guardar('https://www.bilbao.eus/aytoonline/jsp/opendata/movilidad/od_sonometro_mediciones.jsp?idioma=c&formato=json',
                  './datos/base/sonometro_mediciones.json')

#2 Cargar datos en df para proceder a tratarlo
sonometro_mediciones <- leer_json('./datos/base/sonometro_mediciones.json')
head(sonometro_mediciones)

#3 Detectar y tratar valores faltantes
cant_nulos <- contar_nulos(sonometro_mediciones)
if (cant_nulos > 0) {
  message('La cantidad de nulos en el fichero Sonometro Mediciones es de ', cant_nulos)
  sonometro_mediciones <- tratar_nulos(sonometro_mediciones)
}else{
  message('No se han encontrado valores faltantes en el fichero')
}

#4 Comprobar los tipos de dato
str(sonometro_mediciones)
#Convertir decibelios a numeric
sonometro_mediciones$decibelios <- as.numeric(sonometro_mediciones$decibelios)
#convertir fecha medicion a un tipo fecha y hora
sonometro_mediciones$fecha_medicion <- ymd_hms(sonometro_mediciones$fecha_medicion)
#Comprobamos
str(sonometro_mediciones)

#5 Detectar y tratar duplicados
cant_duplicados <- detectar_duplicados(sonometro_mediciones,c("nombre_dispositivo", "decibelios", "fecha_medicion"))
if (nrow(cant_duplicados) > 0) {
  message('Se han detectado duplicados')
  sonometro_mediciones <- eliminar_duplicados(sonometro_mediciones,c("nombre_dispositivo", "decibelios", "fecha_medicion"))
}else{
  message('No se han encontrado valores duplicados en el fichero')
}

#6 Comprobar inconsistencias en columnas numéricas
summary(sonometro_mediciones$decibelios)

#7 Detectar y tratar outliers
detectar_outliers_iqr(sonometro_mediciones,'decibelios')

# ==============================================================================
# LIMPIAR DATOS SONOMETRO UBICACIÓN
# ==============================================================================

#1. Descargar y guardar el archivo
descargar_guardar('https://www.bilbao.eus/aytoonline/jsp/opendata/movilidad/od_sonometro_ubicacion.jsp?idioma=c&f',
                  './datos/base/sonometro_ubicacion.json')

#2 Cargar datos en df para proceder a tratarlo
sonometro_ubicacion <- leer_json('./datos/base/sonometro_ubicacion.json')
head(sonometro_ubicacion)

#2.2 Convertir esa lista rara en una tabla normal
sonometro_ubicacion <- procesar_geojson(sonometro_ubicacion)

#3 Detectar y tratar valores faltantes
cant_nulos <- contar_nulos(sonometro_ubicacion)
if (cant_nulos > 0) {
  message('La cantidad de nulos en el fichero Sonometro Mediciones es de ', cant_nulos)
  sonometro_ubicacion <- tratar_nulos(sonometro_ubicacion)
}else{
  message('No se han encontrado valores faltantes en el fichero')
}

#4 Comprobar los tipos de dato
str(sonometro_ubicacion)
# Convertir Longitud y Latitud a numérico
sonometro_ubicacion$properties.longitude <- as.numeric(sonometro_ubicacion$properties.longitude)
sonometro_ubicacion$properties.latitude <- as.numeric(sonometro_ubicacion$properties.latitude)
# Convertir Status y DeviceTypeId a enteros
sonometro_ubicacion$properties.status <- as.integer(sonometro_ubicacion$properties.status)
sonometro_ubicacion$properties.deviceTypeId <- as.integer(sonometro_ubicacion$properties.deviceTypeId)
# Comprobamos
str(sonometro_ubicacion)


#5 Detectar y tratar duplicados
cant_duplicados <- detectar_duplicados(sonometro_ubicacion,c("properties.name", "properties.serialNumber")) #Un sensor no puede aparecer 2 veces
if (nrow(cant_duplicados) > 0) {
  message('Se han detectado duplicados')
  sonometro_mediciones <- eliminar_duplicados(sonometro_ubicacion,c("nombre_dispositivo", "decibelios", "fecha_medicion"))
}else{
  message('No se han encontrado valores duplicados en el fichero')
}

#6 Comprobar inconsistencias en columnas numéricas
summary(sonometro_ubicacion)

#7 Detectar y tratar outliers
detectar_outliers_iqr(sonometro_ubicacion,'properties.longitude')
detectar_outliers_iqr(sonometro_ubicacion,'properties.latitude')

# ==============================================================================
# JUNTAR SONOMETRO UBICACIÓN Y SONOMETRO MEDICIONES
# ==============================================================================

# 1. Realizamos el Join (Unión normal de tablas)
sonometro_completo <- sonometro_mediciones %>%
  inner_join(
    sonometro_ubicacion, 
    by = c("nombre_dispositivo" = "properties.name")
  )
# 2. Convertimos a objeto espacial (sf) indicando las coordenadas
sonometro_sf <- st_as_sf(
  sonometro_completo,
  coords = c("properties.longitude", "properties.latitude"), # Orden: X (Long), Y (Lat)
  crs = 4326,      # Código EPSG para coordenadas GPS estándar (WGS84)
  remove = FALSE   # FALSE para conservar las columnas de lat/long originales también
)
#3. Comprobamos
class(sonometro_sf) # Debería salir "sf" y "data.frame"

# 4. Limpiamos el nuevo df
cant_nulos <- contar_nulos(sonometro_sf)
if (cant_nulos > 0) {
  message('La cantidad de nulos en el fichero Sonometro Mediciones es de ', cant_nulos)
  sonometro_sf <- tratar_nulos(sonometro_sf)
}else{
  message('No se han encontrado valores faltantes en el fichero')
}

#5 Comprobar los tipos de dato
str(sonometro_sf)

#5 Detectar y tratar duplicados
# PASO 1: Eliminar la columna 'basura' del JSON original.
if("geometry.coordinates" %in% colnames(sonometro_sf)) {
  sonometro_sf$geometry.coordinates <- NULL
}
# PASO 2: Truco de velocidad (Convertir a tabla plana)
sonometro_plano <- sf::st_drop_geometry(sonometro_sf)

# Definimos qué columnas no se pueden repetir
cols_clave <- c("nombre_dispositivo", "fecha_medicion", "decibelios")

# PASO 3: Buscar duplicados
cant_duplicados <- detectar_duplicados(sonometro_plano, cols_clave)

if (nrow(cant_duplicados) > 0) {
  message("Se han detectado ", nrow(cant_duplicados), " duplicados. Eliminando...")
  
  # A) Limpiamos la tabla plana 
  # Guardamos el resultado en una variable temporal 'sonometro_limpio_plano'
  sonometro_limpio_plano <- eliminar_duplicados(sonometro_plano, cols_clave)
  
  # B) Reconstruimos el mapa (sf)
  # Volvemos a convertir la tabla limpia en un objeto espacial
  sonometro_sf <- st_as_sf(
    sonometro_limpio_plano,           # Usamos la tabla limpia
    coords = c("properties.longitude", "properties.latitude"), 
    crs = 4326,
    remove = FALSE
  )
  message("Dataset limpio y reconstruido como objeto espacial.")
  
} else {
  message("No se han encontrado valores duplicados en el fichero.")
}

# ==============================================================================
# LIMPIAR DATOS TRAFICO
# ==============================================================================

#1. Descargar y guardar el archivo
url_trafico <- "https://www.bilbao.eus/aytoonline/srvDatasetTrafico?formato=geojson"
ruta_json_trafico <- "./datos/base/trafico_historico.json"

actualizar_historico_trafico(url_trafico, ruta_json_trafico)


#2 Cargar datos en df para proceder a tratarlo
trafico <- leer_json(ruta_json_trafico)

#2.2 Convertir esa lista  en una tabla normal
df_trafico <- trafico$features
datos_planos <- df_trafico$properties
datos_planos$geometry <- df_trafico$geometry
df_trafico <- datos_planos
head(df_trafico)



#3 Detectar y tratar valores faltantes

# 1. Miramos nulos en las columnas normales
colSums(is.na(select(df_trafico, -geometry)))
# 2. Ver nulos solo del mapa
sum(sapply(df_trafico$geometry, is.null))

#4 Comprobar los tipos de dato
str(df_trafico)
# Convertir métricas de tráfico a enteros
df_trafico$Intensidad <- as.integer(df_trafico$Intensidad)
df_trafico$Ocupacion  <- as.integer(df_trafico$Ocupacion)
df_trafico$Velocidad  <- as.integer(df_trafico$Velocidad)

#Convertir FechaHora a objeto de fecha real
df_trafico$FechaHora <- ymd_hms(df_trafico$FechaHora)

# Verificamos el cambio
str(df_trafico)


#5 Detectar y tratar duplicados
cant_duplicados <- detectar_duplicados(df_trafico,c("CodigoSeccion", "FechaHora")) #Un mismo tramo de carretera no puede tener dos datos distintos a la misma hora exacta
if (nrow(cant_duplicados) > 0) {
  message('Se han detectado duplicados')
  df_trafico <- eliminar_duplicados(df_trafico,c("CodigoSeccion", "FechaHora"))
}else{
  message('No se han encontrado valores duplicados en el fichero')
}

#6 Comprobar inconsistencias en columnas numéricas
summary(df_trafico[, c("Intensidad", "Ocupacion", "Velocidad")])
#No pueden pasar -500 coches por una calle
#6.1 Limpieza valores imposibles
# Contamos cuántos casos raros hay
negativos <- sum(df_trafico$Intensidad < 0 | df_trafico$Ocupacion < 0 | df_trafico$Velocidad < 0)

if (negativos > 0) {
  message(" Se han detectado ", negativos, " registros con valores negativos (códigos de error). Eliminando...")
  
  # Nos quedamos solo con las filas donde todo sea mayor o igual a 0
  df_trafico <- df_trafico[df_trafico$Intensidad >= 0 & 
                             df_trafico$Ocupacion >= 0 & 
                             df_trafico$Velocidad >= 0, ]
  
  message("Valores negativos eliminados. Filas restantes: ", nrow(df_trafico))
} else {
  message("Todos los valores numéricos son lógicos (>= 0).")
}

# Comprobamos de nuevo el summary
summary(df_trafico[, c("Intensidad", "Ocupacion", "Velocidad")])
#7 Detectar y tratar outliers
outliers_velocidad <- detectar_outliers_iqr(df_trafico, "Ocupacion")
outliers_velocidad <- detectar_outliers_iqr(df_trafico, "Velocidad")
outliers_intensidad <- detectar_outliers_iqr(df_trafico, "Intensidad")

# ==============================================================================
# JUNTAR TRAFICO CON SONOMETROS
# ==============================================================================
