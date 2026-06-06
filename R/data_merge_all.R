library(dplyr)

# Import R files
lapply(
  c(
    "data_get_cancensus.R",
    "data_get_cancensus_collect.R",
    "data_get_craigs.R",
    "data_get_osm.R", 
    "data_group_by_ct.R"
  ), 
  source
)

merge_all_data <- function() {
  # Base: Canadian Census
  message("Obtaining Canadian Census data...")
  main_sf <- read_cancensus()
  
  # Add the Craigslist data
  message("Obtaining Craigslist Toronto data...")
  toronto_craigs_ct_sf <- group_craigs_by_ct(
    toronto_census_ct_sf = main_sf, 
    toronto_craigs_sf = read_graigs_data()
  )
  toronto_craigs_ct_sf$ward_code <- NULL
  toronto_craigs_ct_sf$geometry <- NULL
  main_sf <- main_sf |> left_join(
    toronto_craigs_ct_sf, 
    by = c("region_name" = "ct_name")
  ) |> 
    rename(ave_rent_latest = price)
  
  # Add the OSM grocery data
  message("Obtaining OpenStreetMap grocery data...")
  toronto_osm_grocery_ct_sf <- group_osm_groceries_by_ct(
    toronto_census_ct_sf = main_sf, 
    toronto_osm_grocery_point_sf = read_osm_groceries()
  )
  toronto_osm_grocery_ct_sf$ward_code <- NULL
  toronto_osm_grocery_ct_sf$geometry <- NULL
  main_sf <- main_sf |> left_join(
    toronto_osm_grocery_ct_sf, 
    by = c("region_name" = "ct_name")
  ) |> 
    rename(groceries = count)
  
  # Add the OSM restaurant data
  message("Obtaining OpenStreetMap restaurant data...")
  toronto_osm_restaurant_ct_sf <- group_osm_restaurants_by_ct(
    toronto_census_ct_sf = main_sf, 
    toronto_osm_restaurant_point_sf = read_osm_restaurants()
  )
  toronto_osm_restaurant_ct_sf$ward_code <- NULL
  toronto_osm_restaurant_ct_sf$geometry <- NULL
  main_sf <- main_sf |> left_join(
    toronto_osm_restaurant_ct_sf, 
    by = c("region_name" = "ct_name")
  ) |> 
    rename(restaurants = count)
  
  # Add the OSM train station data
  message("Obtaining OpenStreetMap train station data...")
  toronto_osm_station_ct_sf <- group_osm_stations_by_ct(
    toronto_census_ct_sf = main_sf, 
    toronto_osm_station_point_sf = read_osm_stations()
  )
  toronto_osm_station_ct_sf$ward_code <- NULL
  toronto_osm_station_ct_sf$geometry <- NULL
  main_sf <- main_sf |> left_join(
    toronto_osm_station_ct_sf, 
    by = c("region_name" = "ct_name")
    ) |> 
    rename(stations = count)
  
  # ### Add the manipulated columns for personalized scores ### #
  # Divide the median age into three categories
  message("Final manipulation...")
  main_sf <- main_sf |>
    mutate(
      med_age_2021_you_s = ifelse(med_age_2021 < 40, 1, 0),
      med_age_2021_mid_s = ifelse((med_age_2021 >= 40) & (med_age_2021 < 60), 1, 0),
      med_age_2021_sen_s = ifelse(med_age_2021 >= 60, 1, 0)
    )
  
  # Apply log transformation
  main_sf$ave_rent_latest_1 <- log1p(main_sf$ave_rent_latest)
  main_sf$ave_rent_pred_1 <- log1p(main_sf$ave_rent_pred)
  main_sf$pop_density_km_2021_1 <- log1p(main_sf$pop_density_km_2021)
  main_sf$groceries_1 <- log1p(main_sf$groceries)
  main_sf$restaurants_1 <- log1p(main_sf$restaurants)
  main_sf$stations_1 <- log1p(main_sf$stations)
  
  # normalize the columns and add the calculated score column
  norm_d <- function(sf, col) {
    max(sf[[col]], na.rm = TRUE) - min(sf[[col]], na.rm = TRUE)
  }
  main_sf <- main_sf |> 
    mutate(
      ave_rent_latest_s = 
        1 - ((ave_rent_latest_1 - min(main_sf$ave_rent_latest_1, na.rm = TRUE)) / 
        norm_d(sf = main_sf, col = "ave_rent_latest_1")), 
      ave_rent_pred_s = 
        1 - ((ave_rent_pred_1 - min(main_sf$ave_rent_pred_1, na.rm = TRUE)) / 
        norm_d(sf = main_sf, col = "ave_rent_pred_1")), 
      pop_density_km_2021_s = 
        (pop_density_km_2021_1 - min(main_sf$pop_density_km_2021_1, na.rm = TRUE)) / 
        norm_d(sf = main_sf, col = "pop_density_km_2021_1"), 
      groceries_s = 
        (groceries_1 - min(main_sf$groceries_1, na.rm = TRUE)) / 
        norm_d(sf = main_sf, col = "groceries_1"), 
      restaurants_s = 
        (restaurants_1 - min(main_sf$restaurants_1, na.rm = TRUE)) / 
        norm_d(sf = main_sf, col = "restaurants_1"), 
      stations_s = 
        (stations_1 - min(main_sf$stations_1, na.rm = TRUE)) / 
        norm_d(sf = main_sf, col = "stations_1"), 
      personalized_score = 0.0
    ) |> 
    mutate(
      pop_density_km_2021_inv_s = 1 - pop_density_km_2021_s
    ) |> 
    # Replace NAs with 0 (Only two columns have NAs)
    mutate(
      ave_rent_latest_s = ifelse(is.na(ave_rent_latest_s), 0, ave_rent_latest_s), 
      ave_rent_pred_s = ifelse(is.na(ave_rent_pred_s), 0, ave_rent_pred_s)
    )

  return(organize_columns(main_sf = main_sf))
}


organize_columns <- function(main_sf) {
  return(
    main_sf |> 
      select(
        region_name, cd_uid, csd_uid, ward_code, ward_name, 
        population_2021, households_2021, dwellings_2021, 
        # population_2016, households_2016, dwellings_2016, 
        ave_rent_latest, ave_rent_pred, 
        ave_rent_2021, pop_density_km_2021, med_age_2021, 
        groceries, restaurants, stations, 
        ave_rent_latest_s, 
        ave_rent_pred_s, pop_density_km_2021_s, pop_density_km_2021_inv_s, 
        med_age_2021_you_s, med_age_2021_mid_s, med_age_2021_sen_s, 
        groceries_s, restaurants_s, stations_s, 
        personalized_score, 
        area_sqkm, lat_center, lng_center
      )
  )
}
