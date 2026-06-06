# Import R files
source("data_merge_all.R")


# ### Prepare Data ### #
define_variables <- function() {
  domains <- define_domains()
  domain_vars <- names(domains)
  domain_titles <- sapply(unname(domains), function(x) x$title)
  
  variables <- c(
    "ave_rent_latest", 
    "ave_rent_pred", 
    domain_vars[2:3], 
    "groceries", 
    "restaurants", 
    "stations"
  )
  names(variables) <- c(
    "Average Rent (CAD) - Latest", 
    "Average Rent (CAD) - Prediction", 
    domain_titles[2:3],  # Cancensus Data
    "Num of groceries", 
    "Num of restaurants", 
    "Num of train stations"
  )
  return(variables)
}

reverse_lookup <- function(var) {
  variables <- define_variables()
  for (name in names(variables)) {
    if (variables[[name]] == var) {
      return(name)
    }
  }
  stop(paste0("Invalid title: ", title))
}

variables <- define_variables()

if(!exists("main_sf")) {
  main_sf <- merge_all_data()
}
