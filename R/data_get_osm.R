library(sf)

# Read GPKG files and create sf objects
source("config.R")  # to import the filename

# OSM groceries
read_osm_groceries <- function() {
  return(st_read(filename_osf_groceries))
}

# OSM restaurants
read_osm_restaurants <- function() {
  return(st_read(filename_osf_restaurants))
}

# OSM train stations
read_osm_stations <- function() {
  return(st_read(filename_osf_stations))
}
