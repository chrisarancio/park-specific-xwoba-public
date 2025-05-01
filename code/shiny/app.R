library(tidyverse)
library(shiny)
library(dplyr)

data <- readRDS("combined_df.rds")

data <- data |>
  filter(!is.na(value))

players <- data |> 
  filter(type == "Player") |>
  select(player_name) |>
  distinct() |>
  arrange(player_name)

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
                 h3("Project Overview"),
                 p("In the world of baseball analytics, there are many methods used to try to represent a player’s offensive ability but this project focuses mostly on the wOBA and xwOBA metrics. Weighted On-base Average (wOBA) is a metric defined by the MLB as “a version of on-base percentage that accounts for how a player reached base -- instead of simply considering whether a player reached base. The value for each method of reaching base is determined by how much that event is worth in relation to projected runs scored.”  Rather than a simple on-base percentage (OBP), which refers to “how frequently a batter reaches base per plate appearance,”  the weighted OBA (wOBA) has the advantage of considering how different events will have different impacts on scoring runs. For example, the 2023 wOBA formula assigns a linear weight of 1.569 to a triple and a linear weight of 0.833 for a single in that season. "),
                 p("However, there is an even more indicative statistic for a player’s offensive skill called Expected Weighted On-base Average (xwOBA).  xwOBA incorporates “exit velocity, launch angle and, on certain types of batted balls, Sprint Speed” and “allows for the formation of said player's xwOBA based on the quality of contact, instead of the actual outcomes.”  In other words, xwOBA removes defense from the equation and provides probabilities for a single, double, triple, and homerun “based on the results of comparable batted balls since Statcast was implemented Major League wide in 2015.” "),
                 p("For this project, it is important to note that these factors or weights indicate the “adjusted run expectancy of a batting event in the context of the season as a whole.” This analysis trained a model to predict xwOBA for a player on a per-ballpark basis. The reasoning for this is that the outfield walls of each ballpark can vary greatly. In fact, “Kansas City and Toronto are the only two stadiums in MLB with symmetrical outfield dimensions and uniform wall height.”  This means that scoring a homerun at each park will require different exit velocities and launch angles to make it over the outfield walls. Since xwOBA considers exit velocity and launch angle in its calculations, this analysis considers how different ballparks could affect a player’s xwOBA."),
                 h3("What does this chart mean?"),
                 p("Using KNN models trained on pitches from each ballpark and the MLB wOBA weights for each year, we calculated a park-specific xwOBA for each player. We can then compare the average difference between the predicted park xwOBA and the MLB official xwOBA values for every player for the 2015-2024 seasons. These average differences for a certain season and ballpark can then be compared to a specific player's predicted xwOBA during that season and at that ballpark. These differences can highlight certain ballparks where a player may have overperformed or underperformed (compared to the average xwOBA) during a desired season. For example, one can examine which players have overperformed (in terms of xwOBA) at their home ballpark during various seasons.")
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
    
    
    # update the year dropdown based on selected player
    updateSelectInput(session, "year_select", choices = years_available)
  })
  
  output$barPlot <- renderPlot({
    one_player <- data |>
      filter(year == input$year_select, player_name == input$player_select | is.na(player_name))
    
    one_player_fixed <- one_player |>
      filter(type == "Player") |>
      pull(park) |>
      unique() -> parks_with_player_data
    
    one_player_fixed <- one_player |>
      filter(type == "Player" | (type == "Average" & park %in% parks_with_player_data))
    
    ggplot(one_player_fixed, aes(x = park, y = value, fill = type)) +
      geom_bar(stat = "identity", position = position_dodge()) +
      scale_fill_brewer(name = NULL, palette = "Set1", labels = c("League Average", "Player Performance")) +
      labs(title = paste("Park xwOBA Differential for", input$year_select, input$player_select),
           x = "Park",
           y = "Park xwOBA vs MLB xwOBA Difference") +
      theme(
        plot.title = element_text(size = 22, face = "bold", hjust = 0.5),
        axis.title.x = element_text(size = 16),
        axis.title.y = element_text(size = 16),
        axis.text.x = element_text(size = 12), 
        axis.text.y = element_text(size = 12), 
        legend.position = "bottom",
        legend.text = element_text(size = 14),
        plot.margin = margin(20, 20, 0, 20) 
      )
  })
}

# Create Shiny app ----
shinyApp(ui = ui, server = server)
