# ==============================================================================
# ANÁLISIS EXPLORATORIO DE RUIDO Y TRÁFICO
# ==============================================================================

# 1. Cargar funciones de utilidad
source("./scripts/utils.R")

# 2. Definir las librerías necesarias para el reto
mis_paquetes <- c(
  "tidyverse",  # Manipulación y visualización (dplyr, ggplot2, tidyr) 
  "lubridate",  # Gestión de fechas y horas 
  "sf",         # Datos geográficos (GeoJSON) 
  "leaflet"     # Mapas interactivos
)

# 3. Descargar las librerias que nos hacen falta
cargar_librerias(mis_paquetes)

#Verificar los tipos de los datos

str(ruido_Trafico_Bilbao)

ruido_Trafico_Bilbao <- read.csv("./datos/procesados/dataset_final_bilbao.csv", encoding = "UTF-8")
ruido_Trafico_Bilbao$fecha_medicion <- as.POSIXct(ruido_Trafico_Bilbao$fecha_medicion)
ruido_Trafico_Bilbao$FechaHora <- as.POSIXct(ruido_Trafico_Bilbao$FechaHora)
ruido_Trafico_Bilbao$Clave_Tiempo <- as.POSIXct(ruido_Trafico_Bilbao$Clave_Tiempo)

str(ruido_Trafico_Bilbao)

# ==============================================================================
# Creación de variables temporales
# ==============================================================================

# Creamos columnas nuevas basadas en la fecha de medición
ruido_Trafico_Bilbao <- ruido_Trafico_Bilbao %>%
  mutate(
    Hora = hour(fecha_medicion),
    Dia_Semana = wday(fecha_medicion, label = TRUE, abbr = FALSE),
    # Definimos si es fin de semana (Sábado o Domingo) o laboral
    Tipo_Dia = if_else(wday(fecha_medicion) %in% c(1, 7), "Fin de Semana", "Laboral"),
    # Creamos franjas horarias estándar
    Franja = case_when(
      Hora >= 7 & Hora < 14  ~ "Mañana",
      Hora >= 14 & Hora < 21 ~ "Tarde",
      TRUE                   ~ "Noche"
    )
  )

# Comprobamos las nuevas columnas
head(ruido_Trafico_Bilbao[, c("fecha_medicion", "Hora", "Dia_Semana", "Tipo_Dia", "Franja")])

# ==============================================================================
# 1. Análisis por Zonas / Sonómetros
# Objetivo: Identificar qué lugares de Bilbao soportan más ruido de media.
# ==============================================================================

# Agrupamos por sensor para ver la media de ruido e intensidad de tráfico
analisis_zonas <- ruido_Trafico_Bilbao %>%
  group_by(nombre_dispositivo, address) %>%
  summarise(
    Ruido_Medio = mean(decibelios, na.rm = TRUE),
    Intensidad_Media = mean(Intensidad, na.rm = TRUE),
    Velocidad_Media = mean(Velocidad, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  arrange(desc(Ruido_Medio))

# Ver los 5 sitios más ruidosos
head(analisis_zonas, 10)

# Gráfico de Barras: Top 10 sensores con más ruido
ggplot(head(analisis_zonas,10), aes(x = reorder(nombre_dispositivo, Ruido_Medio), y = Ruido_Medio, fill = Ruido_Medio)) +
  geom_col() +
  coord_flip() + # Ponemos las barras horizontales para leer mejor los nombres
  scale_fill_gradient(low = "yellow", high = "red") + # De amarillo a rojo según el ruido
  labs(title = "Top 10 Sonómetros más ruidosos de Bilbao", 
       subtitle = "Basado en la media de decibelios registrados",
       x = "Sensor", y = "Media de Decibelios (dB)") +
  theme_minimal()

# ==============================================================================
# 2. Análisis por Franjas Horarias (Mañana, Tarde, Noche)
# Objetivo: 
# ==============================================================================

# Agrupamos por Franja para ver el comportamiento del ruido
analisis_franjas <- ruido_Trafico_Bilbao %>%
  group_by(Franja) %>%
  summarise(
    Ruido_Medio = mean(decibelios, na.rm = TRUE),
    Intensidad_Media = mean(Intensidad, na.rm = TRUE),
    .groups = 'drop'
  )

print(analisis_franjas)

ggplot(ruido_Trafico_Bilbao, aes(x = Franja, y = decibelios, fill = Franja)) +
  geom_boxplot(alpha = 0.7) +
  labs(title = "Distribución del Ruido por Franja Horaria", 
       x = "Franja del día", y = "Decibelios") +
  theme_light()

# ==============================================================================
# 3. Análisis por Días (Laboral vs Fin de Semana)
# Objetivo: Ver cómo evoluciona el ruido hora a hora comparando los dos tipos de día.
# ==============================================================================

# Calculamos la evolución horaria media
evolucion_tipo_dia <- ruido_Trafico_Bilbao %>%
  group_by(Tipo_Dia, Hora) %>%
  summarise(Ruido_Medio = mean(decibelios, na.rm = TRUE), .groups = 'drop')

# Gráfico de líneas
ggplot(evolucion_tipo_dia, aes(x = Hora, y = Ruido_Medio, color = Tipo_Dia)) +
  geom_line(size = 1.2) +
  geom_point() +
  scale_x_continuous(breaks = 0:23) + # Que se vean todas las horas
  labs(title = "Evolución del Ruido: Día Laboral vs Fin de Semana",
       subtitle = "Patrones horarios de ruido en Bilbao",
       x = "Hora del día", y = "Media Decibelios") +
  theme_minimal()

# ==============================================================================
# 3. Análisis por Días (Laboral vs Fin de Semana)
# Objetivo: Buscar sitios "raros": donde el ruido varía mucho (picos)
#           frente a sitios donde el ruido es siempre el mismo (constante).
# ==============================================================================

# Calculamos la variabilidad (Desviación Estándar)
puntos_dif <- ruido_Trafico_Bilbao %>%
  group_by(nombre_dispositivo, address) %>%
  summarise(
    Media = mean(decibelios, na.rm = TRUE),
    Variabilidad = sd(decibelios, na.rm = TRUE),
    .groups = 'drop'
  )

# Gráfico de Dispersión
ggplot(puntos_dif, aes(x = Media, y = Variabilidad, label = nombre_dispositivo)) +
  geom_point(aes(color = Variabilidad), size = 3) +
  geom_text(vjust = -1, size = 3, check_overlap = TRUE) +
  labs(title = "Zonas Persistentes vs Zonas Variables",
       subtitle = "Alta variabilidad indica ruidos por eventos puntuales",
       x = "Ruido Medio (dB)", y = "Variabilidad (Desviación Estándar)") +
  theme_bw()
