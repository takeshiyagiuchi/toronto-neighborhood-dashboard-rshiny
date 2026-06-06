library(ggpubr)
library(shiny)
library(shinydashboard)
library(shinyjs)

# Import R files
source("data.R")
source("data_personalized_score.R")
source("data_top3.R")
source("graph_rents.R")
source("graph_amenities.R")
source("graph_histogram.R") 
source("map_leaflet.R")
source("ui_style.R")
source("utils.R")


# ######################## #
# ### Set up dashboard ### #
# ######################## #

# ### UI ### #
ui <- dashboardPage(
  skin = "black", 
  # ### Header ### #
  dashboardHeader(
    title = "Toronto Neighbors",
    # Place radioButtons directly within dashboardHeader
    tags$li(
      class = "dropdown", 
      radioButtons(
        inputId = "mode",
        label = "",
        choices = NULL,
        selected = "explore_one_variable",
        inline = TRUE,
        width = NULL,
        choiceNames = c(
          "Explore One Variable", 
          "Personalized Ranking"
        ),
        choiceValues = c(
          "explore_one_variable", 
          "personalized_ranking"
        )
      )
    )
  ),
  # ### Sidebar ### #
  dashboardSidebar(
    # Debugger
    # textOutput("debug"), 
    # Only show this panel if "Explore One Variable" is selected
    conditionalPanel(
      condition = "input.mode == 'explore_one_variable'",
      selectInput(
        inputId = "variable",
        label = "Variable",
        choices = names(variables)
      )
    ), 
    # Only show this panel if "Personalized Ranking" is selected
    conditionalPanel(
      condition = "input.mode == 'personalized_ranking'",
      actionButton(
        inputId = "calculate", 
        label = "Calculate"
      ), 
      sliderInput(
        inputId = "ave_rent_latest", 
        label = "Average Rent (Latest)", 
        min = 0, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      ), 
      sliderInput(
        inputId = "ave_rent_pred", 
        label = "Average Rent (Prediction)", 
        min = 0, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      ), 
      sliderInput(
        inputId = "pop_density", 
        label = "Population Density", 
        min = -10, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      ), 
      sliderInput(
        inputId = "med_age_youth", 
        label = "Median Age (~39)", 
        min = 0, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      ), 
      sliderInput(
        inputId = "med_age_mid", 
        label = "Median Age (40~59)", 
        min = 0, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      ), 
      sliderInput(
        inputId = "med_age_senior", 
        label = "Median Age (60~)", 
        min = 0, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      ), 
      sliderInput(
        inputId = "groceries", 
        label = "Groceries", 
        min = 0, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      ), 
      sliderInput(
        inputId = "restaurants", 
        label = "Restaurants", 
        min = 0, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      ), 
      sliderInput(
        inputId = "stations", 
        label = "Train Stations", 
        min = 0, 
        max = 10, 
        value = 0, 
        ticks = FALSE
      )
    )
  ),
  # ### Body ### #
  dashboardBody(
    # Define the UI style (CSS)
    tags$head(
      tags$style(
        HTML(ui_style)
      )
    ), 
    # Map
    fluidRow(
      style = "background-color: white; height: 350px;",
      leafletOutput("map", height = 350)
    ), 
    # Reset selected CT
    actionButton(
      inputId = "reset_ct", 
      label = "Reset CT"
    ), 
    # Graph and Analysis
    fluidRow(
      style = "background-color: white;",
      column(
        12, 
        tags$span(style = "color: white;", textOutput("clicked_flag"))
      ) 
    ), 
    conditionalPanel(
      condition = "output.clicked_flag == '-'",
      fluidRow(
        style = "background-color: white;",
        column(12, align = "center", h4("The Whole Toronto"), textOutput("toronto")) 
      ), 
      fluidRow(
        style = "background-color: white;",
        valueBoxOutput("high1", width = 4), 
        valueBoxOutput("high2", width = 4), 
        valueBoxOutput("high3", width = 4)
      ), 
    ), 
    conditionalPanel(
      condition = "output.clicked_flag === '-' &&
        !['Num of groceries', 'Num of restaurants', 'Num of train stations'].includes(input.variable) &&
        input.mode == 'explore_one_variable'", 
      fluidRow(
        style = "background-color: white;",
        valueBoxOutput("low1", width = 4), 
        valueBoxOutput("low2", width = 4), 
        valueBoxOutput("low3", width = 4)
      ), 
    ), 
    conditionalPanel(
      condition = "output.clicked_flag == '-'",
      fluidRow(
        style = "background-color: white; height: 250px;",
        column(12, align = "center", h4(" "), plotOutput("histogram", height = "200px"))
      )
    ), 
    conditionalPanel(
      condition = "output.clicked_flag == '*'",
      fluidRow(
        style = "background-color: white;",
        column(12, align = "center", h4("Area Analysis"), textOutput("area_analysis")) 
      ), 
      fluidRow(
        style = "background-color: white; height: 250px;",
        column(6, align = "center", h4(" "), plotOutput("graph_rents", height = "200px")), 
        column(6, align = "center", h4(" "), plotOutput("graph_amenities", height = "200px"))
      ), 
      fluidRow(
        style = "background-color: white;",
        infoBoxOutput("density", width = 6), 
        infoBoxOutput("mid_age", width = 6)
      )
    )
  )
)

# ### Server ### #
server <- function(input, output) {
  # ### Debugging ### #
  # output$debug <- renderText({ paste0(input$variable) })
  
  # ### Reactive ### #
  # variable
  values <- reactiveValues(sf = main_sf, count_calc = 0, ct_name_clicked = NULL)
  observeEvent(input$calculate, {
    values$count_calc <- isolate(values$count_calc) + 1
  })
  variable_selected <- reactive({ input$variable })
  weights <- eventReactive(input$calculate, {
    if (input$pop_density < 0) {
      pop_density_name <- "pop_density_km_2021_inv_s"
      pop_density_val <- -1 * input$pop_density
    } else {
      pop_density_name <- "pop_density_km_2021_s"
      pop_density_val <- input$pop_density
    }
    res <- c(
      input$ave_rent_latest, 
      input$ave_rent_pred, 
      pop_density_val, 
      input$med_age_youth, 
      input$med_age_mid, 
      input$med_age_senior, 
      input$groceries, 
      input$restaurants, 
      input$stations
    )
    names(res) <- c(
      "ave_rent_latest_s", 
      "ave_rent_pred_s", 
      pop_density_name, 
      "med_age_2021_you_s", 
      "med_age_2021_mid_s", 
      "med_age_2021_sen_s", 
      "groceries_s", 
      "restaurants_s", 
      "stations_s"
    )
    return(normalize_vec(vec = res) / 9)
  })
  hist_var <- reactive({
    # Mode: Personalized Ranking
    if (input$mode == "personalized_ranking") {
      # No Calculate pressed yet → use default score column if it exists
      if (values$count_calc < 1) {
        return("personalized_score")   # must be precomputed once in your data
      }
      # If calculate was pressed → use updated score
      return("personalized_score")
    }
    # Mode: Explore
    return(variables[input$variable])
  })
  top3_sf <- reactive({
    req(req(hist_var()))
    return(get_top3_rows(sf = main_sf, var = hist_var()))
  })
  # Clicked Census Tract on the leaflet map
  observeEvent(input$map_shape_click, {
    clicked_point <- input$map_shape_click
    
    if (is.null(clicked_point$lng) || is.null(clicked_point$lat)) {
      values$ct_name_clicked <- NULL
    } else {
      clicked_point_sf <- st_sfc(
        st_point(c(clicked_point$lng, clicked_point$lat)),
        crs = 4326
      )
      selected_row <- main_sf |> 
        filter(st_intersects(geometry, clicked_point_sf, sparse = FALSE))
      
      values$ct_name_clicked <- selected_row$region_name
    }
  })
  observeEvent(input$reset_ct, {
    values$ct_name_clicked <- NULL
  })
  output$clicked_flag <- renderText({
    if (is.null(values$ct_name_clicked)) "-" else "*"
  })
  # ### Leaflet Map ### #
  # The map type changes between single and bivariate. 
  output$map <- renderLeaflet({
    if (input$mode == "personalized_ranking") {
      if(values$count_calc < 1) {
        weights_nv <- c(0, 0, 0, 0, 0, 0, 0, 0, 0)
        names(weights_nv) <- c(
          "ave_rent_latest_s", 
          "ave_rent_pred_s", 
          "pop_density_km_2021_s", 
          "med_age_2021_you_s", 
          "med_age_2021_mid_s", 
          "med_age_2021_sen_s", 
          "groceries_s", 
          "restaurants_s", 
          "stations_s"
        )
      } else {
        weights_nv <- weights()
      }
      values$sf <- calculate_personalized_score(
        main_sf = main_sf, weights_nv = weights_nv
      )
      main_sf <<- values$sf
      leaflet_toronto(
        main_sf = main_sf, 
        variable = "personalized_score", 
        ward = FALSE, 
        logscale = FALSE, 
        palette = "viridis", 
        legend_title = "Personalized Score", 
        marker = TRUE
      )
    } else {
      leaflet_toronto(
        main_sf = main_sf, 
        variable = variables[[variable_selected()]], 
        ward = FALSE, 
        logscale = TRUE, 
        palette = "viridis", 
        legend_title = variable_selected(), 
        marker = TRUE
      )
    }
  })
  
  # ### Graph ### #
  output$histogram <- renderPlot({
    req(hist_var())   # wait until eventReactive has run
    plot_hist(sf = main_sf, var = hist_var(), var_title = input$variable)
  })
  output$graph_rents <- renderPlot({
    plot_rent_bar(main_sf = main_sf, ct_name = values$ct_name_clicked) 
  })
  output$graph_amenities <- renderPlot({
    plot_amenity_bar(main_sf = main_sf, ct_name = values$ct_name_clicked) 
  })
  
  # ### Text ### #
  output$high1 <- renderValueBox({
    target <- get_top3_rows(sf = main_sf, var = hist_var(), asc = FALSE)
    target <- target[1, ]
    valueBox(
      value = round(target[[hist_var()]], digits = 2),
      subtitle = paste0("1st Highest (", target$region_name, " in ", target$ward_name, ")"), 
      icon = icon("arrow-up"),
      color = "blue"
    )
  })
  output$high2 <- renderValueBox({
    target <- get_top3_rows(sf = main_sf, var = hist_var(), asc = FALSE)
    target <- target[2, ]
    valueBox(
      value = round(target[[hist_var()]], digits = 2),
      subtitle = paste0("2nd Highest (", target$region_name, " in ", target$ward_name, ")"), 
      icon = icon("arrow-up"),
      color = "yellow"
    )
  })
  output$high3 <- renderValueBox({
    target <- get_top3_rows(sf = main_sf, var = hist_var(), asc = FALSE)
    target <- target[3, ]
    valueBox(
      value = round(target[[hist_var()]], digits = 2),
      subtitle = paste0("3rd Highest (", target$region_name, " in ", target$ward_name, ")"), 
      icon = icon("arrow-up"),
      color = "green"
    )
  })
  output$low1 <- renderValueBox({
    target <- get_top3_rows(sf = main_sf, var = hist_var(), asc = TRUE)
    target <- target[1, ]
    valueBox(
      value = round(target[[hist_var()]], digits = 2),
      subtitle = paste0("1st Lowest (", target$region_name, " in ", target$ward_name, ")"), 
      icon = icon("arrow-down"),
      color = "purple"
    )
  })
  output$low2 <- renderValueBox({
    target <- get_top3_rows(sf = main_sf, var = hist_var(), asc = TRUE)
    target <- target[2, ]
    valueBox(
      value = round(target[[hist_var()]], digits = 2),
      subtitle = paste0("2nd Lowest (", target$region_name, " in ", target$ward_name, ")"), 
      icon = icon("arrow-down"),
      color = "maroon"
    )
  })
  output$low3 <- renderValueBox({
    target <- get_top3_rows(sf = main_sf, var = hist_var(), asc = TRUE)
    target <- target[3, ]
    valueBox(
      value = round(target[[hist_var()]], digits = 2),
      subtitle = paste0("3rd Lowest (", target$region_name, " in ", target$ward_name, ")"), 
      icon = icon("arrow-down"),
      color = "teal"
    )
  })
  output$area_analysis <- renderText({
    selected_row <- main_sf |> filter(region_name == values$ct_name_clicked)
    paste0(
      "This is the stats for area ", 
      selected_row$region_name, 
      " (in ", 
      selected_row$ward_name, 
      ") "
    )
  })
  output$density <- renderInfoBox({
    selected_row <- main_sf |> filter(region_name == values$ct_name_clicked)
    infoBox(
      "Density (/sqkm)", 
      paste0(round(selected_row$pop_density_km_2021, digits = 2)), 
      icon = icon("people-group"),
      color = "purple"
    )
  })
  output$mid_age <- renderInfoBox({
    selected_row <- main_sf |> filter(region_name == values$ct_name_clicked)
    infoBox(
      "Median Age", 
      paste0(selected_row$med_age_2021), 
      icon = icon("calendar"),
      color = "yellow"
    )
  })
}

# ### Run app ### #
shinyApp(ui, server)
