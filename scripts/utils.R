# ==============================================================================
# GESTIÓN DE LIBRERÍAS
# ==============================================================================

# Función para instalar y cargar librerías automáticamente
cargar_librerias <- function(librerias) {
  # 1. Identificar qué librerías NO están instaladas
  librerias_faltantes <- librerias[!(librerias %in% installed.packages()[,"Package"])]
  
  # 2. Instalar las que falten
  if(length(librerias_faltantes)) {
    message("Instalando librerías faltantes: ", paste(librerias_faltantes, collapse = ", "))
    install.packages(librerias_faltantes)
  }
  
  # 3. Cargar todas las librerías
  message("Cargando librerías...")
  sapply(librerias, require, character.only = TRUE)
}

# ==============================================================================
# FUNCION DE DESCARGA DE FICHEROS SONOMETROS
# ==============================================================================
#Descargar datos y guardarlos
descargar_guardar <- function(url,ruta){
  download.file(url, ruta)
  message("El archivo se ha descargado correctamente y se guardó en ...", ruta)
}

# ==============================================================================
# FUNCION DE DESCARGA DE FICHERO TRAFICO
# ==============================================================================
#Leer el historico de trafico,descargar los ultimos 15 minutos y agregarlos a este guardandolo
actualizar_historico_trafico <- function(url, ruta){

  historico <- fromJSON(ruta, simplifyVector = FALSE)
  
  geojson <- fromJSON(url, simplifyVector = FALSE)
  
  # Añadir las features tal cual vienen
  historico$features <- c(historico$features, geojson$features)
  
  write_json(historico, ruta, pretty = TRUE, auto_unbox = TRUE)
  
  message(paste("Tráfico guardado. Total acumulado:", length(historico$features), "features."))
}

# ==============================================================================
# LECTURA DE JSON CON CODIFICACIÓN 
# ==============================================================================

leer_json <- function(ruta) {
  
  # PASO 1: Leer el archivo como texto plano forzando codificación 'latin1'
  # 'warn = FALSE' evita avisos molestos si falta una línea final
  texto_plano <- readLines(ruta, encoding = "latin1", warn = FALSE)
  
  # PASO 2: Unir todas las líneas en un solo texto gigante
  texto_unido <- paste(texto_plano, collapse = "\n")
  
  # PASO 3: Convertir ese texto ya arreglado a objeto JSON
  datos <- fromJSON(texto_unido)
  
  return(datos)
}

# ==============================================================================
# TRANSFORMACIÓN DE GEOJSON A TABLA
# ==============================================================================

procesar_geojson <- function(datos_json) {
  # 1. Extraemos la parte que contiene los datos (features)
  # Si intentas filtrar 'datos_json' directo, falla porque es una lista.
  df <- datos_json$features
  
  # 2. "Aplanamos" el archivo
  # Esto convierte columnas anidadas como "properties.address" en columnas normales
  df_plano <- jsonlite::flatten(df)
  
  return(df_plano)
}

# ==============================================================================
# GESTIÓN DE VALORES FALTANTES
# ==============================================================================

#Número de filas del dataframe que tienen al menos un NA
contar_nulos <- function(df) {
  nrow(filter(df, if_any(everything(), is.na)))
}
#Eliminamos filas que tengan nulos ya que si esto ocurre es debido a un posible error en sensores
tratar_nulos <- function(df){
  df_limpio <- drop_na(df)
  return(df_limpio)
}

# ==============================================================================
# GESTIÓN DE DUPLICADOS
# ==============================================================================
detectar_duplicados <- function(df, columnas) {
  #1 Contar cuántas veces aparece cada combinación de las columnas)
  conteo <- count(df, across(all_of(columnas)))
  #2 Quedarnos solo con las filas que aparecen más de 1 vez
  duplicados <- filter(conteo, n > 1)
  
  return(duplicados)
}

eliminar_duplicados <- function(df,columnas){
  # Argumento 1: El dataframe (df)
  # Argumento 2: Las columnas donde buscar duplicados (usando across y all_of)
  # Argumento 3: .keep_all = TRUE (importante para no perder el resto de datos)
  df_limpio <- distinct(df, across(all_of(columnas)), .keep_all = TRUE)
  message('Se han eliminado los duplicados del fichero.')
  return(df_limpio)
}

# ==============================================================================
# DETECTAR OUTLIERS
# ==============================================================================
detectar_outliers_iqr <- function(df, columna) {
  
  # 1. Calcular los Cuartiles (Q1 y Q3)
  # na.rm = TRUE es vital para que no falle si hay algún hueco en los datos
  Q1 <- quantile(df[[columna]], 0.25, na.rm = TRUE)
  Q3 <- quantile(df[[columna]], 0.75, na.rm = TRUE)
  
  # 2. Calcular el Rango Intercuartílico (la caja central del gráfico)
  IQR <- Q3 - Q1
  
  # 3. Calcular los límites (Bigotes)
  lower <- Q1 - 1.5 * IQR   # Límite inferior
  upper <- Q3 + 1.5 * IQR   # Límite superior
  
  # 4. Filtrar: Nos quedamos con lo que esté FUERA de los límites
  # Estructura: filter(DATOS, CONDICION)
  # La barra vertical | significa "O" (OR logic)
  outliers <- filter(df, df[[columna]] < lower | df[[columna]] > upper)
  
  return(outliers)
}
