library(readr)
library(sf)


# Group the Craigslist Toronto rent data by Census Tract
group_craigs_by_ct <- function(
    toronto_census_ct_sf, 
    toronto_craigs_sf
) {
  toronto_census_ct_sf$geometry2 <- st_geometry(toronto_census_ct_sf)
  toronto_census_ct_sf <- toronto_census_ct_sf |> 
    st_join(toronto_craigs_sf, join = st_contains) |> 
    rename(ct_name = region_name) |> 
    group_by(ct_name) |> 
    summarize(
      price = round(mean(price_num)), 
      ward_code = first(ward_code)
    )
  st_geometry(toronto_census_ct_sf) <- "geometry"
  return(toronto_census_ct_sf)
}

# Group the OSM grocery data by Census Tract
group_osm_groceries_by_ct <- function(
    toronto_census_ct_sf, 
    toronto_osm_grocery_point_sf
) {
  toronto_census_ct_sf$geometry2 <- st_geometry(toronto_census_ct_sf)
  return(
    toronto_census_ct_sf |> 
      st_join(toronto_osm_grocery_point_sf, join = st_contains) |> 
      rename(ct_name = region_name) |> 
      group_by(ct_name) |> 
      summarize(
        count = n(), 
        ward_code = first(ward_code)
      )
  )
}

# Group the OSM restaurant data by Census Tract
group_osm_restaurants_by_ct <- function(
    toronto_census_ct_sf, 
    toronto_osm_restaurant_point_sf
) {
  toronto_census_ct_sf$geometry2 <- st_geometry(toronto_census_ct_sf)
  return(
    toronto_census_ct_sf |> 
      st_join(toronto_osm_restaurant_point_sf, join = st_contains) |> 
      rename(ct_name = region_name) |> 
      group_by(ct_name) |> 
      summarize(
        count = n(), 
        ward_code = first(ward_code)
      )
  )
}

# Group the OSM train station data by Census Tract
group_osm_stations_by_ct <- function(
    toronto_census_ct_sf, 
    toronto_osm_station_point_sf
) {
  toronto_census_ct_sf$geometry2 <- st_geometry(toronto_census_ct_sf)
  return(
    toronto_census_ct_sf |> 
      st_join(toronto_osm_station_point_sf, join = st_contains) |> 
      rename(ct_name = region_name) |> 
      group_by(ct_name) |> 
      summarize(
        count = n(), 
        ward_code = first(ward_code)
      )
  )
}
