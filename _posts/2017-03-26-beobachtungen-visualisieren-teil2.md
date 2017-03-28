---
layout: post
title: Visualisation Schmetterlingsdaten - Tutorial Teil 1
abstract: Abstract
author: Markus Dumke
tags: Visualisation Schmetterlingsdaten
comments: true
---

## Erstellen einer Shiny App
Zunächst müssen wir das R Paket Shiny installieren. Dieses erstellt im Folgenden die Visualisation. Eine Shiny App besteht aus 2 Teilen: einem `ui.R` Skript, dass die grafische Benutzeroberfläche (Buttons etc., die der Nutzer klicken kann) erstellt und ein `server.R` Skript, dass festlegt, was passieren soll, wenn z.B. ein Button geklickt wird. Zudem ist es nützlich ein weiteres Skript `global.R` zu haben, in dem Code nur einmal bei Start der App ausgeführt wird, z.B. das Laden der Pakete und Daten. In `global.R` schreiben wir zunächst:

```r
library(shiny)
library(leaflet) # for the map

# load data
data <- read.csv2("data.csv")
```

## Karte erstellen

Zunächst fangen wir mit einer einfachen App an, die einfach eine Karte anzeigt. Schritt für Schritt werden wir dann diese erweitern. Dafür fügen wir in `ui` einen `leafletOutput` ein, damit wird standardmässig die Openstreetmap Karte eingebunden. Die Breite der Karte setzen wir auf 100% der Bildschirmbreite, die Höhe auf 700 Pixel.

```r
ui <- fluidPage(
  leafletOutput("map", width = "100%", height = "700px")
)
```

In `server.R` fügen wir dann folgenden Code ein, der die Karte dann tatsächlich erstellt. Mit `setView()` setzen wir den aktuellen Kartenausschnitt. Die ersten Argumente bestimmen Höhen- und Breitengrad des Kartenmittelpunkts, die letzte Zahl den Zoom Faktor.

```r
server <- function(input, output, session) {
  
  output$map <- renderLeaflet({
    leaflet() %>% addTiles() %>% setView(11, 49, 7)
  })
}
```
Jetzt haben wir bereits eine lauffähige App, die in Rstudio durch Klicken auf **Run App** gestartet werden kann. Es sollte sich ein Fenster öffnen, in dem eine leere Openstreetmap Karte gezeigt wird. Der vollständige Code findet sich [hier](https://gist.github.com/markdumke/c574874f432fb542fb18b5f253d273c3).

## Funde auf der Karte darstellen

Als nächstes wollen wir die Koordinaten der Fundpunkte auf der Karte darstellen. Dafür fügen wir in  `renderLeaflet()` ein `addCircleMarkers()` ein, das die Punkte der Karte hinzufügt.

```r
output$map <- renderLeaflet({
    leaflet(data) %>% addTiles() %>% setView(9.5, 47.5, 9) %>% 
      addCircleMarkers(fillOpacity = 1, opacity = 1)
```

## Sidebar hinzufügen

Als nächster Schritt wäre es cool, eine Möglichkeit zu haben, auszuwählen, welche Daten angezeigt werden sollen, z.B. nur eine bestimmte Art oder nur Beobachtungen ab einem bestimmten Jahr.
Dafür fügen wir in `ui.R` eine Sidebar ein, die es uns ermöglicht, die Daten zu filtern. In Shiny sind zahlreiche Inputs möglich, z.B. Buttons, Checkboxes und TextInputs, für mehr Informationen siehe [Shiny Widgets](http://shiny.rstudio.com/gallery/widget-gallery.html).


Zunächst fügen wir einen `selectizeInput` ein, mit dem wir die Art auswählen können.

```r
ui <- fluidPage(
  sidebarPanel(
    selectizeInput("Art", label = "Art", 
      selected = "Polygonia c-album",
      choices = levels(data$Art), 
      multiple = TRUE)
  ),
  mainPanel(leafletOutput("Karte", width = "100%", height = "700px"))
)
```

Damit bei Auswahl einer Art, auch nur die Punkte dieser Art auf der Karte angezeigt werden, müssen wir in `server.R` ein subset der Daten bilden. Falls keine Art ausgewählt ist, werden alle Punkte angezeigt.

```r
  # check if input is empty, then do not subset
  data_subset <- reactive({
    if (!is.null(input$Art)) {
      species_selected <- input$Art
    } else {
      species_selected <- levels(data$Art)
    }
    data[data$Art %in% species_selected, ]
  })
      
  output$map <- renderLeaflet({
    leaflet(data_subset()) %>% 
      addTiles() %>% 
      setView(9.5, 47.5, 9) %>% 
      addCircleMarkers(fillOpacity = 1, opacity = 1)
  })      
```

Der Code findet sich [hier](https://gist.github.com/markdumke/35b6f7cc4b9b4c0e6166853303d576e7).

Natürlich können wir in der Sidebar noch zahlreiche weitere Inputs hinzufügen. Z.B. weitere `selectizeInput` oder auch `sliderInput` für Jahr oder Höhe. In `ui.R` kann das ganze dann z.B. so aussehen:

```r
ui <- fluidPage(
  sidebarPanel(
    selectizeInput("Art", label = "Art", 
                   selected = "Polygonia c-album",
                   choices = levels(data$Art), multiple = TRUE),
    selectizeInput("Stadium", label = "Stadium", selected = "Falter",
                   multiple = TRUE, choices = levels(data$Stadium)),
    selectizeInput("Bundesland", label = "Bundesland", 
                   selected = "Bayern", 
                   choices = levels(data$Bundesland), 
                   multiple = TRUE),
    selectizeInput("Beobachter", label = "Beobachter", 
                   selected = "Markus Dumke",
                   choices = levels(data$Beobachter), 
                   multiple = TRUE),
    sliderInput("Jahr", "Jahr", min = min(data$Jahr), 
                max = max(data$Jahr), step = 1, ticks = TRUE, 
                value = c(min(data$Jahr), max(data$Jahr))),
    sliderInput("altitude", label = "Höhe", min = 0, step = 100, 
                ticks = TRUE, max = max(data$altitude), 
                value = c(0, max(data$altitude)))
  ),
  mainPanel(leafletOutput("Karte", width = "100%", height = "700"))
)
```

In `server.R` müssen wir dann `data_subset`anpassen, sodass auch nach den anderen Variablen gefiltert wird. Dafür müssen wir in `global.R` noch das `shinybutterfly` Paket laden (`devtools::install_github("markdumke/shinybutterfly")`). In `server.R` ersetzen wir dann das bisherige `data_subset` durch:

```r
  # build subset of data.frame ------------------------------
  # input id and name of variable in dataframe (column name) 
    must be the same!
  data_subset <- reactive({
    textinput_vars <- c("Art", "Stadium", "Land", "Geschlecht", 
      "Beobachter")
    for (i in textinput_vars){
      if (!is_input_empty(input[[i]])) {
        data <- data[data[, i] %in% input[[i]], ]
      }
    }
    sliderinput_vars <- c("altitude", "Jahr")
    for (i in sliderinput_vars){
      data <- data[data[, i] >= input[[i]][1] & 
        data[, i] <= input[[i]][2], ]
    }
    data
  })
```
Code [hier](https://gist.github.com/markdumke/6f925faf00ea3016321b4d4a4c201409).

## Datentabelle einfügen

Nützlich ist es zusätzlich zur Karte auch noch die Funde in einer Tabelle (ähnlich zu Excel) anzeigen zu lassen. Datentabellen können mit dem R Paket `DT` hinzugefügt werden. In `ui.R` ändern wir jetzt das Design, sodass die Shiny App mehrere Tabs nebeneinander enthalten kann. In einem neuen Tab fügen wir dann eine Datentabelle hinzu, die alle Funde anzeigt, die auch auf der Karte sichtbar sind. 

```r
ui <- fluidPage(
  navbarPage("Visualisation Tagfalter Daten",
    tabPanel("Karte",
      sidebarPanel(
      # ... unchanged
      )
    ),
    tabPanel("Daten", dataTableOutput("table"))
  )
)

```

Jetzt haben wir eine App mit zwei Tabs. In `server.R` müssen wir nun die Datentabelle erzeugen. Um Fotos und anderen HTML Content darzustellen, muss `escape = FALSE` gesetzt werden.

```r
  output$table <- DT::renderDataTable(
    data_subset(),
    rownames = FALSE,
    escape = FALSE # to include html, e.g. images in datatable
  )
```

Der Code der App bis hierhin kann [hier](https://gist.github.com/markdumke/d22ddd59cebed89741ee95019c475524) gefunden werden 

Die Shiny App enthält inzwischen bereits zahlreiche nützliche Funktionen. Lese in [Teil 3]() weiter wie Daten in der App erfasst werden können.

{% include disqus.html %}
