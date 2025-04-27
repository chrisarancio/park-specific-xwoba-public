library(tidyverse)
library(shiny)
library(dplyr)

project_dir <- rstudioapi::getActiveProject()
setwd(project_dir)
data <- readRDS("./data/new_parks/final_parks_and_mlb_xwoba.rds")

data <- data |>
  filter(!is.na(value))

players <- data |> 
  filter(type == "Player") |>
  select(player_name) |>
  distinct()

ui <- fluidPage(
  
  # App title ----
  titlePanel("Park-Specific-xwOBA Dashboard"),
  tags$p("Chris Arancio and Luke Walsh", style = "font-weight: normal;"),
  tags$hr(),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      selectInput(inputId = "player_select",
                  label = "Select Player",
                  choices = players$player_name,
                  selected = "Bryce Harper"),
      selectInput("year_select", 
                  "Select Year", 
                  choices = NULL,
                  selected = 2015)
      ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      tabsetPanel(
        tabPanel("Plot",
                 plotOutput(outputId = "barPlot")
        ),
        tabPanel("About",
                 h3("What does this chart mean?"),
                 p("Something idk"),
                 p("really cool")
        )
      )
    )
  )
)

# Define server logic required to draw a map ----
server <- function(input, output, session) {
  
  observe({
    selected_player <- input$player_select
    years_available <- unique(data$year[
      data$player_name == selected_player & 
        !is.na(data$value) & 
        !is.na(data$year)
    ])
    years_available <- years_available[!is.na(years_available)]
    
    
    # Update the year dropdown based on selected player
    updateSelectInput(session, "year_select", choices = years_available)
  })
  
  output$barPlot <- renderPlot({
    one_player <- data |>
      filter(year == input$year_select, player_name == input$player_select | is.na(player_name))
    
    ggplot(one_player, aes(x = park, y = value, fill = type)) +
      geom_bar(stat = "identity", position = position_dodge()) +
      scale_fill_brewer(name = NULL, palette = "Set1", labels = c("League Average", "Player Performance")) +
      labs(title = paste("Park xwOBA Differential for", input$year_select, input$player_select),
           x = "Park",
           y = "Park xwOBA vs MLB xwOBA Difference") +
      theme(
        plot.title = element_text(size = 22, face = "bold", hjust = 0.5),
        axis.title.x = element_text(size = 16),
        axis.title.y = element_text(size = 16),
        axis.text.x = element_text(size = 12),  # Increase x-axis tick label size
        axis.text.y = element_text(size = 12), 
        legend.position = "bottom",
        legend.text = element_text(size = 14),
        plot.margin = margin(20, 20, 0, 20) 
      )
  })
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)
