# https://stackoverflow.com/questions/45710087/plotting-sfc-polygon-in-leaflet
library(leaflet)

# Import R files
source("data_top3.R")


# A function to create a leaflet to show data on the map of Toronto
leaflet_toronto <- function(
  main_sf,  # The coordinate system needs to be WGS84
  variable,  # The target column to illustrate on the map
  ward,  # Boolean. If TRUE, the data is averaged by ward group
  logscale,  # Boolean. If TRUE, the variable is colored by logscale
  palette,  # The palette to color the values
  legend_title, 
  marker  # Boolean
){
  # Group by ward
  if (ward) {
    main_sf <- group_by_ward(main_sf)
  }
  
  if (logscale) {
    main_sf$col <- log1p(main_sf[[variable]])
  } else {
    main_sf$col <- main_sf[[variable]]
  }
  
  # The definition of color palette
  pal <- colorNumeric(palette = palette, domain = main_sf$col)
  # pal <- colorQuantile(palette = palette, domain = main_sf[[variable]], n = 5)

  # Create a leaflet
  output <- leaflet(main_sf) |> 
    addTiles() |> 
    setView(lng = -79.2832, lat = 43.7032, zoom = 10) |>  # for Toronto view
    addPolygons(
      fillColor = ~pal(x = main_sf$col), # Apply the palette here
      color = "black", # Outline color
      weight = 0.1,
      fillOpacity = 0.7,
      highlightOptions = highlightOptions(
        weight = 3,
        color = "#666",
        fillOpacity = 0.9,
        bringToFront = TRUE
      )
    )
  # Legend if needed
  if (logscale) {
    output <- output |> 
      addLegend(
        pal = pal, 
        values = main_sf$col, 
        labFormat = labelFormat(
          transform = function(x) expm1(x),   # inverse transform for labels
          digits = 0
        ), 
        title = legend_title
      )
  } else {
    output <- output |> 
      addLegend(
        pal = pal, 
        values = main_sf$col, 
        title = legend_title
      )
  }
  
  if (marker) {
    high3_sf <- get_top3_rows(sf = main_sf, var = variable, asc = FALSE)
    if (grepl("groceries|restaurants|stations|personalized_score", variable)){
      hl3_sf <- high3_sf
    } else {
      low3_sf <- get_top3_rows(sf = main_sf, var = variable, asc = TRUE)
      hl3_sf <- bind_rows(high3_sf, low3_sf)
    }
    output <- output |> 
      addMarkers(
        data = hl3_sf,
        lat = ~lat_center,
        lng = ~lng_center,
        popup = ~region_name
      )
  }

  return(output)
}
