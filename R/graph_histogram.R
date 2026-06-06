library(ggplot2)


plot_hist <- function(
  sf,  # An sf object. Assuming it is main_sf
  var,  # The target variable to plot
  var_title  # The title of the variable
) {
  res <- ggplot(
    data = sf, 
    aes(
      x = sf[[var]], 
      weight = 1, 
      fill = after_stat(x)
    )
  ) +
    geom_histogram() + 
    scale_fill_viridis_c() +
    labs(
      x = var_title,
      y = "Number of Census Tracts", 
      fill = var_title
    )
  
  return(res)
}