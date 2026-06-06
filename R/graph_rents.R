library(ggplot2)
library(dplyr)


plot_rent_bar <- function(main_sf, ct_name) {
  # Extract the row with the specified ct_name
  selected_row <- main_sf |> 
    filter(region_name == ct_name)
  # Create a tibble of rent data
  rents_tbl <- tibble(
    name = c("Latest", "Prediction"), 
    rent = c(selected_row$ave_rent_latest, selected_row$ave_rent_2021)
  )
  # Plot
  res <- rents_tbl |> 
    ggplot(
      aes(
        x = factor(name, level=c("Prediction", "Latest")), 
        y = rent
      )
    ) +
    geom_bar(
      stat = "identity", width = 0.3, fill = "#EE6969"
    ) + 
    geom_text(aes(label = rent), vjust = 0.5) +
    theme_bw() +
    labs(title = "Average Rent", y = "Average Rent (CAD)") + 
    theme(
      plot.title = element_text(hjust = 0.5), 
      axis.title.y = element_blank()
    ) + 
    coord_flip()
  
  if (is.na(selected_row$ave_rent_latest)) {
    if (is.na(selected_row$ave_rent_2021)) {
      res <- res + 
        geom_text(aes(x = "Latest", y = 0, label = "No Data"), vjust = 0) + 
        geom_text(aes(x = "Prediction", y = 0, label = "No Data"), vjust = 0)
    } else {
      res <- res + geom_text(aes(x = "Latest", y = selected_row$ave_rent_2021 / 2, label = "No Data"), vjust = 0)
    }
  }

  return(res)
}
