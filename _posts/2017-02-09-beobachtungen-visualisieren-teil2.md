---
layout: post
title: Visualisation Schmetterlingsdaten - Teil 2
abstract: Abstract
author: Markus Dumke
tags: Visualisation Schmetterlingsdaten
comments: true
---

## Erstellen einer Shiny App
Zunächst müssen wir das Paket Shiny installieren. Dieses erstellt im Folgenden die Visualisation. Eine Shiny App besteht immer aus 2 Teilen: einem ui.R Skript, dass die grafische Benutzeroberfläche (Buttons etc., die der Nutzer klicken kann) erstellt und ein server.R Skript, dass festlegt, was passieren soll, wenn z.B. ein Button geklickt wird. Zunächst müssen wir das Peket laden und die Daten einlesen. Ausserdem brauchen wir noch das leaflet Paket, das die Karten zur Verfügung stellt. Platziere dafür folgenden Code in deiner ui.R **und** in deiner server.R Datei:

```r
library(shiny)
library(leaflet)

# load data
data <- read.csv2("data_proprocessed.csv", encoding = "utf8")
```

Zunächst fangen wir mit einer einfachen App an, die einfach eine Karte anzeigt. Dafür fügen wir in ui.R einen leafletOutput ein, damit wird standardmässig die Openstreetmap Karte eingebunden. Die Breite der Karte setzen wir auf 100% der Bildschirmbreite, die Höhe auf 700 Pixel (Wichtig: Es ist nicht möglich, beide auf 100% zu setzen!)

```r
ui <- fluidPage(
  leafletOutput("map", width = "100%", height = "700")
)
```

In server.R fügen wir dann folgenden Code ein, der die Karte dann tatsächlich erstellt. Mit `setView()` setzen wir den aktuellen Kartenausschnitt. Die ersten Argumente bestimmen Höhen- und Breitengrad des Kartenmittelpunkts, die letzte Zahl den Zoom Faktor. Ändere diese nach Belieben.

```r
shinyServer(
  function(input, output, session) {
    
    output$map <- renderLeaflet({
      leaflet() %>% addTiles()  %>%
        setView(11, 49, 7)
    })
  }
)
```
Jetzt haben wir bereits eine lauffähige App, wenn du in Rstudio auf **Run App** klickst, sollte sich ein Fenster öffnen, in dem eine leere Openstreetmap Karte gezeigt wird.

Als nächstes wollen wir die Koordinaten als Punkte auf der Karte darstellen lassen. Dafür ändern wir server.R, sodass folgender Code dort steht:

```r
shinyServer(
  function(input, output, session) {
    
    points <- reactive({
      cbind(data$longitude, data$latitude)
    })
        
    output$map <- renderLeaflet({
      leaflet() %>% addTiles()  %>%
        setView(11, 49, 7) %>% 
        addCircleMarkers(data = points(), fillOpacity = 1, 
                         opacity = 1)
    })
  }
)
```

Jetzt sollte der Output mit **Run App** etwa so aussehen:

![Shiny App]({{ site.url }}/assets/app2.JPG)

Als nächster Schritt wäre es cool, eine Möglichkeit zu haben, welche Daten angezeigt werden sollen, z.B. nur eine bestimmte Art oder nur Beobachtungen ab einem bestimmten Jahr darzustellen.
Dafür fügen wir in ui.R eine sidebar ein, die es uns erlaubt genau diese Auswahlen zu treffen. In Shiny sind zahlreiche Inputs möglich, z.B. Buttons, Checkboxes und TextInputs, für mehr siehe hier: <a href="http://shiny.rstudio.com/gallery/widget-gallery.html" target="_blank">Shiny Widgets</a> 

```r
ui <- fluidPage(
  sidebarPanel(
    selectizeInput("Art", label = "Art", selected = "Polygonia c-album",
                   choices = levels(data$Art), multiple = TRUE)),
    mainPanel(leafletOutput("Karte", width = "100%", height = "700"))
)
```

Damit bei Auswahl einer Art, auch nur die Punkte dieser Art auf der Karte angezeigt werden, müssen wir in server.R ein subset bilden.

```r
shinyServer(
  function(input, output, session) {
    
    data_subset <- reactive({
      data[data$Art %in% input$Art, ]
    })
    
    points <- reactive({
      cbind(data_subset()$longitude, data_subset()$latitude)
    })
        
    output$Karte <- renderLeaflet({
      leaflet() %>% addTiles()  %>%
        setView(11, 49, 7) %>% 
        addCircleMarkers(data = points(), fillOpacity = 1, 
                         opacity = 1)
    })
  }
)
```

Nun wird jedes Mal wenn ein Input verändert wird, d.h. eine neue Art ausgewählt wird, erneut `renderLeaflet` aufgerufen und die Karte neu erzeugt. Das ist nicht unbedingt das erwünschte Verhalten. Um das zu umgehen, müssen wir das `addCircleMarkers` aus dem `renderLeaflet` nehmen und in ein `leafletProxy` Aufruf schreiben, dieser verhindert das die gesamte Karte neu erzeugt werden muss, sodass bei einer neuen Auswahl der aktuelle Kartenausschnitt erhalten bleibt. Mit `clearGroup` werden alle alten Punkte von der Karte gelöscht und danach die neuen basierend auf der aktuellen Artenauswahl dargestellt.

```r
shinyServer(
  function(input, output, session) {
    
    data_subset <- reactive({
      data[data$Art %in% input$Art, ]
    })
    
    points <- reactive({
      cbind(data_subset()$longitude, data_subset()$latitude)
    })
        
    output$Karte <- renderLeaflet({
      leaflet() %>% addTiles()  %>%
        setView(11, 49, 7)
    })
    
    observeEvent(input$Art, {
      leafletProxy("Karte") %>% clearGroup("points") %>%
        addCircleMarkers(data = points(), fillOpacity = 1, 
                         opacity = 1, group = "points")
    })
  }
)
```

Schon ganz nützlich. Natürlich können wir in der Sidebar noch zahlreiche weitere Inputs hinzufügen. Z.B. weitere `selectizeInput` oder auch `sliderInput` für Jahr oder Höhe. In ui.R kann das ganze dann so aussehen:

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
                   choices = levels(data$Bundesland), multiple = TRUE),
    selectizeInput("Beobachter", label = "Beobachter", 
                   selected = "Markus Dumke",
                   choices = levels(data$Beobachter), multiple = TRUE),
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

In server.R müssen wir dann `data_subset`anpassen:

```r
shinyServer(
  function(input, output, session) {
    
    data_subset <- reactive({
      data[data$Art %in% input$Art & 
           data$Stadium %in% input$Stadium & 
           data$Bundesland %in% input$Bundesland & 
           data$Beobachter %in% input$Beobachter & 
           data$altitude >= input$altitude[1] & 
           data$altitude <= input$altitude[2] &
           data$Jahr >= input$Jahr[1] & data$Jahr <= input$Jahr[2], ]
    })
    
    # Rest bleibt so ...
  }
)
```

Die App sollte jetzt etwa so aussehen:

![Shiny App]({{ site.url }}/assets/app3.JPG)

### Satellitenbilder hinzufügen
Manchmal sind auch Satelliten- oder Geländekarten mit Höhenlinien nützlich. Diese können wir recht einfach hinzufügen. Zudem fügen wir noch eine Suche hinzufügen. Diese Funktionen sind in dem Paket `leaflet.extras`, das wir zunächst noch installieren müssen. Um das Paket zu installieren, ist ausserdem die neueste Version des Pakets `leaflet` nötig, beides können wir einfach von Github installieren.

```r
install("devtools")
devtools::install_github("rstudio/leaflet")
devtools::install_github("bhaskarvk/leaflet.extras")
library(leaflet.extras)
```

Dann ändern wir den Aufruf von `output$Karte <- ...` in server.R so:

```r
    output$Karte <- renderLeaflet({
      leaflet() %>% setView(11, 49, 7) %>% 
      addSearchOSM() %>%
      addTiles(group = "OSM") %>%
      addProviderTiles("Esri.WorldImagery", group = "Satellit") %>%
      addProviderTiles("Esri.WorldTopoMap", group = "Gelände") %>%
      addLayersControl(baseGroup = c("OSM", "Satellit", "Gelände"))
    })
```

Jetzt können wir zwischen verschiedenen Karten wechseln und zudem einfach nach Orten suchen.

### Messtischblätter und Quadranten anzeigen
Praktisch wäre weiterhin MTBs und Quadranten anzeigen zu lassen. Hier habe ich bereits vordefinierte Objekte erstellt, die am besten einfach hier heruntergeladen werden können: Link

In server.R fügen wir oben im Skript (am besten nach den library Aufrufen) folgenden Code hinzu

```r
load("mtb_list.rds")
load("mtb_spatial.rds")
load("mtb_4_spatial.rds")
load("mtb_4_list.rds")

source("show_only_mtb_within_map_bounds.R", encoding = "utf8")
```


```r

```

```r

```

```r

```

```r

```



The code can be found here: [Github](https://github.com/markdumke/lepivis)
{% include disqus.html %}
