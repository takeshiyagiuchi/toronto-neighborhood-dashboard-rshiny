library(ggplot2)
library(dplyr)


plot_amenity_bar <- function(main_sf, ct_name) {
  # Extract the row with the specified ct_name
  selected_row <- main_sf |> 
    filter(region_name == ct_name)
  # Create a tibble of rent data
  rents_tbl <- tibble(
    name = c("Groceries", "Restaurants", "Train Station"), 
    count = c(selected_row$groceries, selected_row$restaurants, selected_row$stations)
  )
  # Plot
  res <- rents_tbl |> 
    ggplot(
      aes(
        x = factor(name, level=c("Groceries", "Restaurants", "Train Station")), 
        y = count
      )
    ) +
    geom_bar(
      stat = "identity", width = 0.3, fill = "#398564"
    ) + 
    geom_text(aes(label = count), vjust = 0.5) +
    theme_bw() +
    labs(title = "Local Amenities", y = "Count") + 
    theme(
      plot.title = element_text(hjust = 0.5), 
      axis.title.x = element_blank()
    )
  
  return(res)
}
