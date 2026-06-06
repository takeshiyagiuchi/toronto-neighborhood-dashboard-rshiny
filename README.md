# Toronto Neighborhood Dashboard (R Shiny)

## Overview

Finding a suitable neighborhood can be challenging, especially for newcomers. While rental platforms provide detailed information about individual listings, they often fail to give a comprehensive view of neighborhood-level factors such as affordability, accessibility, and amenities.

This project presents an **interactive R Shiny dashboard** that helps users explore and compare neighborhoods in Toronto using a data-driven approach. The platform integrates multiple data sources and provides both exploratory and personalized analysis tools to support better housing decisions.

**Target users:** tenants, students, and newcomers seeking a convenient way to evaluate neighborhoods.

---

## Motivation

Choosing where to live involves more than just rent. Factors such as access to food, transportation, and community characteristics play a significant role in quality of life. However, these pieces of information are typically scattered across different platforms.

This dashboard aims to:
- Consolidate key neighborhood-level information in one place  
- Reduce the need to switch between multiple data sources  
- Provide intuitive visualizations for quick decision-making  

---

## Data Sources

To balance **data quality and real-world relevance**, we combined multiple sources:

### Canadian Census (2021)
Reliable and comprehensive dataset providing:
- Average rent  
- Population density  
- Median age  

To address outdated rent values:
- Census rents were adjusted using official housing inflation rates  
- Supplemented with real rental data from Craigslist  

---

### Craigslist Toronto
Used to capture **current rental market conditions**:
- Rent from live listings  

Limitations:
- Incomplete coverage (~55% of areas missing listings)  

Mitigation:
- Combined with adjusted Census data  
- Removed outliers (e.g., extremely low or high rents)  

---

### OpenStreetMap (OSM)
Provides spatial data for amenities:
- Grocery stores  
- Restaurants  
- Train stations  

Limitations:
- Community-maintained → potential inconsistencies  

Mitigation:
- Careful filtering and query design  

---

## Dashboard Design

The dashboard is designed to minimize complexity while enabling both **exploration** and **decision-making**.

### 1. Explore One Variable
- View a single variable (e.g., rent, grocery density) on a choropleth map  
- Understand distribution patterns across Toronto  
- Inspect top and bottom neighborhoods  

👉 Best for: understanding individual factors  

---

### 2. Personalized Ranking
- Assign weights to variables (rent, amenities, demographics)  
- Compute a custom score for each neighborhood  
- Visualize results based on user preferences  

👉 Best for: multi-factor decision-making  

<p align="center">
  <img src="report/figures/fig1.png" width="600">
</p>
<p align="center">
  <em>Figure 1. Basic Layout.</em>
</p>

<p align="center">
  <img src="report/figures/fig2.png" width="600">
</p>
<p align="center">
  <em>Figure 2. Explore One Variable mode – Across Toronto.</em>
</p>

<p align="center">
  <img src="report/figures/fig3.png" width="600">
</p>
<p align="center">
  <em>Figure 3. Explore One Variable mode – A Census Tract area is selected.</em>
</p>

<p align="center">
  <img src="report/figures/fig4.png" width="600">
</p>
<p align="center">
  <em>Figure 4. Personalized Ranking mode – Across Toronto.</em>
</p>

<p align="center">
  <img src="report/figures/fig5.png" width="600">
</p>
<p align="center">
  <em>Figure 5. Personalized Ranking mode – A Census Tract area is selected.</em>
</p>

---

## Scoring Method

To ensure meaningful comparisons:

- Log scaling is applied to reduce skewed distributions  
- Rent is treated as a **minimization objective**  
- Amenities are treated as **maximization objectives**  
- Population density supports both preferences (positive or negative weights)  
- Median age is grouped into categories to reflect realistic preferences  

---

## Visualization

The dashboard consists of two main components:

### Map
- Choropleth map of Toronto (by Census Tract)  
- Interactive (zoom, pan, click)  
- Highlights top and bottom areas  

### Graphs & Summary
- Histograms for overall distribution  
- Area-specific statistics on selection  
- Bar charts for rent and amenities  

---

## Key Features

- Interactive choropleth maps  
- Dual exploration modes (single variable vs. ranking)  
- User-controlled weighting system  
- Integration of multiple real-world datasets  
- Combined spatial and statistical insights  

---

## How to Run

1. Ensure all project files are in the same directory  
2. Open and run:

```r
source("main.R")
```

---

## Limitations

- **Data freshness:** Census data is outdated; rental data is incomplete  
- **Data consistency:** OSM and Craigslist may contain noise  
- **Geographical units:** Census Tracts are not intuitive for users  
- **Data granularity:** Some variables are only available at coarse levels  

---

## Future Improvements

- Add more variables (e.g., schools, walkability, demographics)  
- Improve neighborhood labeling and navigation  
- Expand to other Canadian cities  
- Enhance UI clarity and user guidance  
- Provide ranking summaries for each neighborhood  

---