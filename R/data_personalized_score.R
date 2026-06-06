calculate_personalized_score <- function(
  main_sf,
  weights_nv  # A named vector. The names are column names and the values are weights
) {
  main_sf <- main_sf |>
    mutate(
      personalized_score = rowSums(
        across(all_of(names(weights_nv))) * weights_nv
      )
    )
  return(main_sf)
}

