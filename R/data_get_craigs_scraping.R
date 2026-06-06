library(chromote)
library(openxlsx)
library(purrr)
library(rvest)
library(stringr)


# Scrape rent data from Craigslist Toronto and save to an excel file
# (which means no return value)
scrape_craigs_data <- function() {
  # ### Get a list of the latest posts on the page ### #
  # This page created with JavaScript prevents us from getting all the posts 
  # just by visiting the page. You need to scroll all down.
  # We use chromote to enable it.
  
  # Rental apartment/housing search page of Craigslist Toronto
  url_base <- "https://toronto.craigslist.org/search/apa?sort=date#search=2~list~0"
  
  # Start a new chromote session
  chrome_session <- ChromoteSession$new()
  # chrome_session$view()  # If you want to see what's actually happening on the browser
  chrome_session$Page$navigate(url_base)
  chrome_session$Page$loadEventFired()  # Wait for the page to fully load
  
  # Acquire the posts while scrolling down
  post_links <- c("")
  # Usually 10 iterations are enough
  for (i in 1:10) {
    # Scroll down. Divide it into two steps since the first scroll does not work sometimes
    chrome_session$Runtime$evaluate(expression = "window.scrollBy(0, 50);")
    Sys.sleep(5)
    chrome_session$Runtime$evaluate(expression = "window.scrollBy(0, 8000);")
    Sys.sleep(5)
    
    # Get full HTML at this current point
    page_html <- chrome_session$Runtime$evaluate(
      "document.documentElement.outerHTML"
    )$result$value
    apa_html <- read_html(page_html)
    
    # Append new links
    post_links_old <- post_links
    post_links_new <- apa_html |> 
      html_elements("a") |> 
      html_attr("href") |> 
      unique()
    post_links <- c(post_links_old, post_links_new)
    # Exclude unnecessary links
    matches <- str_detect(post_links, pattern = "apa/d")
    post_links <- post_links[matches] |> unique()
    print(paste0("num of urls: ", length(post_links)))
  }
  
  post_links <- post_links[!is.na(post_links)]
  print(paste0("num of urls: ", length(post_links)))
  
  # Close the session
  chrome_session$close()
  
  
  # ### Access each URL and collect info to create an sf object  ### #
  # Get necessary info from a URL
  get_post_info <- function(url) {
    print(url)
    Sys.sleep(runif(1, 0.5, 1.5))  # polite delay
    # Read HTML from the URL
    post_html <- tryCatch(read_html(url), error = function(e) return(NULL))
    if (is.null(post_html)) {
      return(
        tibble(
          url = url,
          price = NA,
          latitude = NA,
          longitude = NA, 
          name = NA, 
          type = NA, 
          housing = NA, 
          address = NA, 
          beds = NA, 
          baths = NA
        )
      )
    }
    # cat(as.character(post_html))
    
    # Extract JSON inside <script id="ld_posting_data">
    post_json <- post_html |> 
      html_element("#ld_posting_data") |> 
      html_text() |> 
      fromJSON()
    
    tibble(
      url = post_links[1],
      price = post_html |> html_element(".price") |> html_text(),
      latitude = post_json$latitude,
      longitude = post_json$longitude, 
      name = post_json$name, 
      type = post_json[["@type"]], 
      housing = post_html |> html_element(".housing") |> html_text(), 
      address = post_json$address$streetAddress, 
      beds = post_json$numberOfBedrooms, 
      baths = post_json$numberOfBathroomsTotal
    )
  }
  
  # Apply the function to your URL list
  craigs_tbl <- map_dfr(post_links, get_post_info)
  
  # Save the tibble to an Excel file
  source("config.R")  # to import a variable "filename_craigs_tor"
  write.xlsx(craigs_tbl, filename_craigs_tor)
}

# run
scrape_craigs_data()
