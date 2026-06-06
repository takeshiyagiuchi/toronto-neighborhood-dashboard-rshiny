library(dplyr)


get_top3_rows <- function(
  sf,  # An sf object. Assuming it is main_sf 
  var,  # The target variable
  asc  # Boolean. If TRUE, ascending, descending otherwise
) {
  sf <- sf |> filter(!is.na(.data[[var]]))
  if (asc) {
    sf <- sf |> arrange(.data[[var]]) |> head(3)
    return (sf)
  } else {
    sf <- sf |> arrange(desc(.data[[var]])) |> head(3)
    return (sf)
  }
}
