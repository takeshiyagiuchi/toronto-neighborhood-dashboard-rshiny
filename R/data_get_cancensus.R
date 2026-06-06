library(sf)

# Read GPKG files and create sf objects
source("config.R")  # to import the filename

# OSM groceries
read_cancensus <- function() {
  main_sf <- st_read(filename_cancensus)
  st_geometry(main_sf) <- "geometry"
  return(main_sf)
}
