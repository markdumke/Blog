library(shiny)
library(leaflet)
library(leaflet.extras)

load("mtb_list.rds")
load("mtb_spatial.rds")
load("mtb_4_spatial.rds")
load("mtb_4_list.rds")

source("show_only_mtb_within_map_bounds.R", encoding = "utf8")

data <- read.csv2("data_preprocessed.csv", encoding = "utf8", stringsAsFactors = TRUE)

server <- function(input, output, session){

    data_subset <- reactive({
      species_selected <- ifelse(!is.null(input$Art), input$Art, levels(data$Art))
      data[data$Art %in% species_selected, 
           # data$Stadium %in% input$Stadium & 
           # data$Bundesland %in% input$Bundesland & 
           # data$Beobachter %in% input$Beobachter & 
           # data$altitude >= input$altitude[1] & data$altitude <= input$altitude[2] &
           # data$Jahr >= input$Jahr[1] & data$Jahr <= input$Jahr[2]
            ]
    })
    
    points <- reactive({cbind(data_subset()$longitude, data_subset()$latitude)})
       
    output$map <- renderLeaflet({
    leaflet() %>% addTiles() %>% setView(11, 48.5, 7) %>% 
      addLayersControl(overlayGroups = c("MTB"),
                       options = layersControlOptions(collapsed = FALSE))# %>%
      #addSearchOSM()
    })
    
    observe({
      leafletProxy("map") %>% clearGroup("points") %>%
        addCircleMarkers(data = points(), fillOpacity = 1, opacity = 1, group = "points")
    })
    
  global <- reactiveValues(DOMRdy = FALSE)
  autoInvalidate <- reactiveTimer(1000)

  observe({
    autoInvalidate()
    if(global$DOMRdy){
      session$sendCustomMessage(type = "findInput", message = "")
    }
  })

  session$onFlushed(function() {
    global$DOMRdy <- TRUE
  })
    
    observe({if (!is.null(input$MTB)){
    if (input$MTB == TRUE) {
      if (input$map_zoom > 8) {
        inside_bounds <- unlist(is_mtb_inside_bounds(mtb_list, input$map_bounds))
        if(any(inside_bounds)){
          mtb_rectangle <- lapply(mtb_list[inside_bounds], function(x) {
            y <- matrix(nrow = 2, ncol = 2)
            y[1, ] <- x[1, ]
            y[2, ] <- x[3, ]
            y})
          mtb <- as.vector(Reduce(rbind, mtb_rectangle))
          n <- length(mtb)
          leafletProxy("map") %>%  clearGroup("MTB") %>%
            addRectangles(mtb[seq(1, n/2, by = 2)], mtb[seq(n/2 + 1, n, by = 2)],
                          mtb[seq(2, n/2, by = 2)], mtb[seq(n/2 + 2, n, by = 2)],
                          fill = FALSE, color = "red", weight = 0.5, group = "MTB")
        }

      } else {
        leafletProxy("map") %>% clearGroup("MTB")
      }
    } else {
      leafletProxy("map") %>% clearGroup("MTB")
    }}
  })
  }

# shinyApp(ui, server)
