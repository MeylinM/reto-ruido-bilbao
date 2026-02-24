# Análisis de Ruido Urbano y Tráfico en Bilbao 🚗🔊

![R](https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white)
![Power Bi](https://img.shields.io/badge/power_bi-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![GitHub last commit](https://img.shields.io/github/last-commit/MeylinM/reto-ruido-bilbao?style=for-the-badge)

Este repositorio contiene el proyecto final para la asignatura **Sistemas de BigData** del **Curso de especialización en Inteligencia Artificial y Big Data** del centro de Formación Profesional Tartanga. 

El objetivo principal de este proyecto es realizar un análisis integral de la red de sonómetros en Bilbao para comprender y caracterizar los niveles de ruido en diferentes áreas de la ciudad y explorar su relación con el tráfico.

## Fuentes de Datos
Los datos han sido obtenidos a través de las siguientes fuentes abiertas:
* **Sonómetros - Mediciones:** Niveles de ruido en decibelios (formato JSON).
* **Sonómetros - Ubicación:** Coordenadas geográficas y metadatos de los sensores (formato GeoJSON).
* **Tráfico en tiempo real:** Información sobre intensidad, ocupación y velocidad en los tramos de carretera (formato GeoJSON).

## Tecnologías y Herramientas Utilizadas
* **Lenguajes y Entornos:** R, RStudio.
* **Librerías principales (R):** `tidyverse` (`dplyr`, `ggplot2`, `tidyr`), `sf` (análisis espacial), `lubridate` (series temporales), `httr2` y `jsonlite` (consumo de APIs).
* **Business Intelligence:** Power BI Desktop.

## Estructura del Repositorio
* `datos/`
  * `base/`: Archivos originales descargados mediante las APIs.
  * `procesados/`: Dataset final estructurado e integrado (`dataset_final_bilbao.csv`), listo para su análisis en Power BI.
* `powerbi/`: Archivo `.pbix` con el cuadro de mando funcional y modelo en estrella.
* `scripts/`: Código fuente modular en R.
  * `utils.R`: Funciones reutilizables para descarga, limpieza y detección de outliers IQR.
  * `00_Descarga_trafico_historico.R`: Script iterativo para generar un dataset histórico de tráfico.
  * `Descarga_Limpieza.R`: Pipeline principal de preparación y calidad del dato.
  * `Analisis.R`: Análisis exploratorio y extracción de conocimiento.
* `Analisis_Relacion_Ruido_Trafico_Bilbao.pdf`: Documentación detallada, conclusiones e impacto.

## Metodología
1. **Adquisición Automatizada:** Desarrollo de un script iterativo que consulta la API de tráfico cada 20 minutos para construir un histórico robusto.
2. **Integración Espacio-Temporal:** Unión de las fuentes mediante cruce geográfico utilizando la función `st_nearest_feature` de la librería `sf` y sincronización temporal redondeando a bloques de 15 minutos (creación de la variable `Clave_Tiempo`).
3. **Calidad del Dato:** Tratamiento de valores nulos (NA), filtrado de errores lógicos de los sensores (como valores negativos en intensidad) y manejo de outliers.
4. **Análisis Exploratorio (EDA):** Identificación de patrones agrupando los datos por zonas/sonómetros, franjas horarias y diferenciando entre días laborales y de fin de semana.
5. **Cuadro de Mando:** Construcción de un modelo de datos en esquema de estrella en Power BI, con medidas DAX explícitas (`Promedio_Ruido`, `Promedio_Intensidad_Tráfico`) para interactividad dinámica.

## Conclusiones Destacadas
* Se confirma que el tráfico rodado es el principal vector de contaminación acústica en Bilbao. Existe una correspondencia directa entre la intensidad del tráfico y el ruido.
* El área cubierta por el sensor `BI-RUI-021` se identifica como la zona de estrés acústico prioritaria y el punto más crítico tanto en congestión como en decibelios.
* Muchos puntos de la ciudad operan en el límite superior del confort acústico (>65 dB) recomendado por la OMS durante el día, indicando una carga ambiental crónica.
* Existe un "desfase temporal" evidente; los días laborables presentan un ascenso brusco del ruido en las primeras horas de la mañana, mientras que los fines de semana la curva es mucho más suave.

---
*Proyecto desarrollado por Meylin Gutiérrez Montoya*.
