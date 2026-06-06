library(readxl)
library(sf)

# Read the scraped data (an excel file) as a tibble and convert it to an sf object
read_graigs_data <- function() {
  # Read an excel file
  source("config.R")  # to import a variable "filename_craigs_tor"
  craigs_tbl <- read_excel(filename_craigs_tor)
  
  craigs_sf <- craigs_tbl |> 
    st_as_sf(
      coords = c("longitude", "latitude"), 
      crs = 4326,  # WGS84 for leaflet
      remove = FALSE
    ) |> 
    mutate(
      price_num = as.numeric(parse_number(price))
    ) |> 
    filter(price_num > 1 & price_num < 10000)  # Exclude outliers
  
  return(craigs_sf)
}
