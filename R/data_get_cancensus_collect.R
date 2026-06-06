library(cancensus)
library(dplyr)
library(opendatatoronto)
library(sf)


# ### Targeting data domains and comparisons
# Define the target data domain
define_domains <- function(){
  return(
    list(
      ave_rent_2021 = list(
        title = "Average Rent (CAD) - 2021",
        census_col = "v_CA21_4318: Average monthly shelter costs for rented dwellings ($) (59)"
      ), 
      pop_density_km_2021 = list(
        title = "Population Density (/sqkm)",
        census_col = ""
      ), 
      med_age_2021 = list(
        title = "Median Age",
        census_col = "v_CA21_389: Average age"
      )
    )
  )
}

get_inflation_rates <- function(){
  # https://www.toronto.ca/community-people/community-partners/
  # social-housing-providers/affordable-housing-operators/
  # rent-increase-guideline-for-affordable-housing-program/
  return(
    c(
      rate_inflation_2022 = 1.012, 
      rate_inflation_2023 = 1.025, 
      rate_inflation_2024 = 1.025, 
      rate_inflation_2025 = 1.025
    )
  )
}

# ### Create an sf object for Canada Census data ### # 
get_cancensus <- function(){
  # Get Toronto City Wards Data
  # *Canada Census uses unique geographic area definitions which do not include
  #  ward units. We need Toronto City Wards data to aggregate the smaller area
  #  unit (Census Tract, CT).
  # https://open.toronto.ca/dataset/city-wards/
  toronto_ward_sf <- search_packages("City Wards") |>
    list_package_resources() |> 
    filter(name == "City Wards Data") |> 
    get_resource() |> 
    rename(
      ward_code = "AREA_SHORT_CODE", 
      ward_name = "AREA_NAME"
    ) |> 
    select(ward_code, ward_name) |>
    st_transform(26917)  # NAD83/UTM17N: to calculate area accurately. Can't be WGS84 here yet
  
  
  # ### Retrieve Data from Canada Census ### #
  # Read the config file to retrieve the Canada Census API key
  source("config.R")
  
  # Specify dataset variables
  vectors <- c(
    "v_CA21_4318",  # "Average monthly shelter costs for rented dwellings ($) (59)"
    "v_CA21_389",  # "Average age", but actually median age (total)
    "v_CA21_390",  # "Average age", but actually median age (male)
    "v_CA21_391"  # "Average age", but actually median age (female)
  )
  
  domains <- define_domains()

  # Retrieve data from Canada Census
  toronto_census_ct_sf <- get_census(
    dataset = "CA21",  # for 2021 Census
    regions = list(CMA = "35535"),  # code for Toronto CMA
    vectors   = vectors,
    level     = "CT",  # Census Tracts: the largest unit within the ward
    geo_format = "sf", 
    resolution = "simplified",
    labels = "detailed",
    use_cache = TRUE,
    quiet = FALSE,
    api_key = cancensus_api_key
  ) |> 
    rename(
      region_name = "Region Name", 
      cd_uid = "CD_UID", 
      csd_uid = "CSD_UID", 
      population_2021 = "Population", 
      households_2021 = "Households", 
      dwellings_2021 = "Dwellings", 
      population_2016 = "Population 2016", 
      households_2016 = "Households 2016", 
      dwellings_2016 = "Dwellings 2016", 
      area_sqkm = "Area (sq km)", 
      ave_rent_2021 = domains$ave_rent_2021$census_col, 
      med_age_2021 = domains$med_age_2021$census_col
    ) |> 
    mutate(
      ave_rent_pred = round(ave_rent_2021 * prod(get_inflation_rates()), digit = 0), 
      pop_density_km_2021 = population_2021 / area_sqkm
    ) |>
    select(
      region_name, cd_uid, csd_uid, 
      population_2021, households_2021, dwellings_2021, 
      # population_2016, households_2016, dwellings_2016, 
      ave_rent_2021, ave_rent_pred, pop_density_km_2021, 
      med_age_2021, area_sqkm
    ) |>
    st_transform(26917)  # NAD83/UTM17N: to calculate area accurately. Can't be WGS84 here yet
  
  
  # ### Join toronto_ward_sf into toronto_census_ct_sf ### #
  # Define a function to join
  join_ct_ward <- function(toronto_census_ct_sf, toronto_ward_sf){
    # Set up variables
    all_columns <- c(colnames(toronto_census_ct_sf), colnames(toronto_ward_sf))
    all_columns <- all_columns[all_columns != "geometry"]
    toronto_census_ct_sf$area_ct <- as.numeric(st_area(toronto_census_ct_sf$geometry))
    toronto_ward_sf$geometry2 <- st_geometry(toronto_ward_sf)
    # Join
    output_sf <- toronto_census_ct_sf |> 
      st_join(toronto_ward_sf, join = st_intersects) |> 
      transform(
        area_intersection = mapply(
          function(x, y) {as.numeric(st_area(st_intersection(x, y)))}, 
          x = geometry, 
          y = geometry2
        )
      ) |> 
      mutate(area_prop = area_intersection / area_ct) |> 
      group_by(across(all_of(colnames(toronto_census_ct_sf)))) |>
      slice_max(order_by = area_prop, n = 1, with_ties = FALSE) |> 
      filter(area_prop > 0.50) |> 
      select(all_of(all_columns)) |> 
      st_transform(4326)  # WGS84 for leaflet
    
    return(output_sf)
  }
  
  # Perform join
  toronto_census_ct_sf <- join_ct_ward(toronto_census_ct_sf, toronto_ward_sf)
  
  # Add the center coordinates
  col_names <- c(colnames(toronto_census_ct_sf), "lat_center", "lng_center")
  col_names <- col_names[col_names != "geometry"]
  centroid_sf <- st_centroid(toronto_census_ct_sf)
  center_coordinates_tbl <- st_coordinates(centroid_sf)
  toronto_census_ct_sf <- bind_cols(toronto_census_ct_sf, center_coordinates_tbl) |>
    mutate(lng_center = X, lat_center = Y)
  
  return(toronto_census_ct_sf)
}

# An example run
# toronto_census_ct_sf <- get_cancensus()

# ### Group the Canada Census sf object by ward ### #
group_by_ward <- function(toronto_census_ct_sf) {
  return(
    toronto_census_ct_sf |>
      group_by(ward_code) |>
      summarise(
        population_2021 = sum(population_2021), 
        households_2021 = sum(households_2021), 
        dwellings_2021 = sum(dwellings_2021), 
        # population_2016 = sum(population_2016), 
        # households_2016 = sum(households_2016), 
        # dwellings_2016 = sum(dwellings_2016), 
        area_sqkm = sum(area_sqkm), 
        ave_rent_2021 = mean(ave_rent_2021), 
        pop_density_km_2021 = mean(pop_density_km_2021), 
        med_age_2021 = mean(med_age_2021)
      )
  )
}

# Save data to a GPKG file
# source("config.R")  # to import the file names
# message("Obtaining Canadian Census data...")
# st_write(get_cancensus(), dsn = filename_cancensus)
