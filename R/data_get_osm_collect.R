library(dplyr)
library(osmdata)
library(sf)


# Get the Toronto polygon to define the outline
define_toronto_bbox <- function() {
  return(
    c(
      left = -79.6392, 
      bottom = 43.403221, 
      right = -79.115952, 
      top = 43.855457
    )
  )
}

get_toronto_boundary <- function() {
  toronto_bbox <- define_toronto_bbox()
  return(
    opq(toronto_bbox) |> 
      add_osm_feature(key = "boundary", value = "administrative") |> 
      osmdata_sf() |> 
      {\(x) x$osm_multipolygons }() |> 
      filter(name == "Toronto") |> 
      select(name) |> 
      st_transform(4326)  # adjust to the target sf's
  )
}

# Get groceries in Toronto
get_toronto_groceries <- function() {
  toronto_bbox <- define_toronto_bbox()
  toronto_poly_sf <- get_toronto_boundary()
  return(
    opq(toronto_bbox) |> 
      add_osm_feature(
        key = "shop", 
        value = c("supermarket", "convenience", "greengrocer", "bakery", "deli")
      ) |> 
      osmdata_sf() |> 
      {\(x) x$osm_points }() |> 
      st_intersection(toronto_poly_sf) |> 
      select(name, brand) |> 
      filter(!is.na(name)) |> 
      st_transform(4326)  # WGS84 for leaflet
  )
}

# Get restaurants in Toronto
get_toronto_restaurants <- function() {
  toronto_bbox <- define_toronto_bbox()
  toronto_poly_sf <- get_toronto_boundary()
  return(
    opq(toronto_bbox) |> 
      add_osm_feature(
        key = "amenity", 
        value = c("restaurant", "fast_food", "cafe")
      ) |> 
      osmdata_sf() |> 
      {\(x) x$osm_points }() |> 
      st_intersection(toronto_poly_sf) |> 
      select(name, amenity, brand) |> 
      filter(!is.na(name)) |> 
      st_transform(4326)  # WGS84 for leaflet
  )
}

# Get transit stops in Toronto
get_toronto_stations <- function() {
  toronto_bbox <- define_toronto_bbox()
  toronto_poly_sf <- get_toronto_boundary()
  return(
    opq(toronto_bbox) |> 
      add_osm_feature(
        key = "railway", 
        value = c("station", "subway_entrance")
      ) |> 
      osmdata_sf() |> 
      {\(x) x$osm_points }() |> 
      st_intersection(toronto_poly_sf) |> 
      select(name, network) |> 
      filter(!is.na(name)) |> 
      st_transform(4326)  # WGS84 for leaflet
  )
}

# Save each data to a GPKG file
source("config.R")  # to import the file names
message("Obtaining OpenStreetMap grocery data...")
st_write(get_toronto_groceries(), dsn = filename_osf_groceries)
message("Obtaining OpenStreetMap restaurant data...")
st_write(get_toronto_restaurants(), dsn = filename_osf_restaurants)
message("Obtaining OpenStreetMap train station data...")
st_write(get_toronto_stations(), dsn = filename_osf_stations)
