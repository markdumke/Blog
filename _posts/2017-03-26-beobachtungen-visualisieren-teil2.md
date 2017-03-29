---
layout: post
title: Visualisation Schmetterlingsdaten - Tutorial Teil 1
abstract: Abstract
author: Markus Dumke
tags: Visualisation Schmetterlingsdaten
comments: true
---

In diesem Tutorial wollen wir lernen, wie eine einfache Datenvisualisation mithilfe der Statistik-Software R erstellt werden kann. Siehe auch den vorherigen Artikel [Schmetterlingsbeobachtungen darstellen mit R Shiny](https://markdumke.github.io///2017/03/08/Schmetterlingsbeobachtungen-darstellen-mit-Shiny-Leaflet.html).

## Vorbereitungen
Zunächst einmal brauchen wir 
<a href="https://cran.r-project.org/bin/windows/base/" target="_blank">R</a> und 
<a href="https://www.rstudio.com/products/rstudio/download/" target="_blank">RStudio</a> 
(die kostenlose Version reicht aus). 
Installiere R und RStudio als erstes auf deinem PC und erstelle in RStudio ein neues Projekt (File -> New Project -> New Directory -> Empty Project). 
In RStudio öffnen wir dann ein neues Skript, das wir als "app.R" abspeichern. Dieses wird mal die App, die die Visualisation startet.

## Daten
Basis der Visualisation sind natürlich Daten. Für das Tutorial werden wir im Folgenden einen kleinen Testdatensatz verwenden (mit frei erfundenen Beobachtungen). 
Dieser kann hier gefunden und heruntergeladen werden: [Rohdaten](https://github.com/markdumke/shinybutterfly/blob/master/inst/application/rawdata.csv)

Ein Beispiel-Rohdatensatz `raw_data.csv` kann hier gefunden werden (Link)
und sieht ungefähr folgendermassen aus:

|Datum      |Art               | Anzahl|Stadium | latitude| longitude|
|:----------|:-----------------|------:|:-------|--------:|---------:|
|02.04.2017 |Gonepteryx rhamni |     15|Falter  | 47.630 N|  9.7348 E|
|19.08.2015 |Gonepteryx rhamni    |      5|Falter  | 47.561 N|  9.7813 E|
|02.04.2017|Aglais io         |    3|Falter  | 47.549 N|  9.9134 E|
|... |...      |    ...|...  | ...|  ...|

## Datenaufbereitung

In R können wir den Datensatz mit den folgenden Zeilen einlesen:

```r
data <- read.csv2("rawdata.csv", encoding = "utf8")
```

Zunächst müssen wir diesen Datensatz ein wenig aufbereiten, um ihn für die App nutzbar zu machen. Wichtig ist, dass der Datensatz Koordinaten (d.h. zwei Spalten `latitude` (der Breitengrad) und `longitude` (der Höhengrad)) enthält, die wir auf der Karte darstellen wollen.

Diese sollten als Zahlen vorliegen, ein korrekter Längengrad ist z.B. `longitude = 11.3124`, ein Breitengrad z.B. `latitude = 48.21453`.
Falls die Koordinaten in einem anderen Format sind, müssen wir sie erst transformieren. Dafür habe ich die Funktion `extract_coordinates` geschrieben, die mit dem `shinybutterfly` Paket geladen werden kann.

Dafür müssen wir das Paket erst einmal installieren, das funktioniert mit folgendem Code (da das Paket nur auf Github verfügbar ist, müssen wir vorher noch das Paket `devtools` installieren):

```r
install.packages("devtools")
devtools::install_github("markdumke/shinybutterfly")
```
Nach der Installation müssen wir zunächst das Paket mit `library()` laden.

```r
library(shinybutterfly)

# extract coordinates from character
# e.g "11,069 E" will be 11.069
data$latitude <- extract_coordinates(data$latitude)
data$longitude <- extract_coordinates(data$longitude)
```

Mithilfe der Koordinaten lassen sich dann zahlreiche weitere Informationen automatisch bestimmen, z.B. in welchem Land, Bundesland, Kreis und Gemeinde der Fund liegt sowie die Höhenlage. Aus dem Datum lassen sich Jahr, Monat, Tag im Jahr und Tag herauslesen. Der vollständige Code dafür findet sich [hier](https://gist.github.com/markdumke/36e4005fc5c49246cccee9dc4d6011d4).

Die fertig aufbereiteten Daten finden sich dann hier:
[Daten](https://github.com/markdumke/shinybutterfly/blob/master/inst/application/data.csv)
Diese Daten wollen wir im Folgenden interaktiv auf einer Karte darstellen.

## Erstellen der Visualisation mit Shiny
Für die Visualisation verwenden wir das R Paket `Shiny`, das für gut für interaktive Datenvisualisation geeignet ist. Mehr Informationen über Shiny [hier](https://shiny.rstudio.com/). Eine Shiny App besteht meist aus 2 Teilen: einer `ui`, die die grafische Benutzeroberfläche (z.B. Buttons, die der Nutzer klicken kann, um eine bestimmte Art auszuwählen) erstellt und einer Funktion `server`, die festlegt, was passieren soll, wenn z.B. der Button geklickt wird. Zudem gibt es noch Code, der nur einmal bei Start der App ausgeführt werden muss, z.B. das Laden der Pakete und Daten. Dieses schreiben wir einfach ganz oben in unser `app.R` Skript. Dabei ist es möglich die App in einem Skript `app.R` zu haben, oder drei Skripts `ui.R`, `server.R` und `global.R` anzulegen, die die einzelnen Komponenten enthalten. Im Folgenden werden wir nur ein Skript `app.R` verwenden, das alle drei Komponenten enthält.

In `app.R` laden wir zunächst die aufbereiteten Daten und laden wir das Paket `shiny` und das `leaflet` Paket, das die Karten bereitstellt.

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

Darunter fügen wir dann den folgenden Code für die `server` Funktion ein, der die Karte dann tatsächlich erstellt. `addTiles` lädt die Karte und mit `setView()` legen wir den aktuellen Kartenausschnitt fest. Dabei bestimmen die ersten beiden Argumente Höhen- und Breitengrad des Kartenmittelpunkts, die letzte Zahl den Zoom Faktor.

```r
server <- function(input, output, session) {
  
  output$map <- renderLeaflet({
    leaflet() %>% addTiles() %>% setView(11, 49, 7)
  })
}
```
Jetzt haben wir bereits eine lauffähige App, die in Rstudio durch Klicken auf **Run App** gestartet werden kann. Es sollte sich ein Fenster öffnen, in dem eine leere Openstreetmap Karte gezeigt wird. Der vollständige Code unserer App zum jetzigen Zeitpunkt findet sich [hier](https://gist.github.com/markdumke/c574874f432fb542fb18b5f253d273c3).

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

Damit bei Auswahl einer Art, auch nur die Punkte dieser Art auf der Karte angezeigt werden, müssen wir im `server` Aufruf die Daten nach den ausgewähltem Input filtern. Falls keine Art ausgewählt ist, werden alle Punkte angezeigt (es sind also alle Arten ausgewählt).

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

Natürlich können wir in der Sidebar noch zahlreiche weitere Inputs hinzufügen. Z.B. weitere `selectizeInput` oder auch `sliderInput` für Jahr oder Höhe. In der `ui` kann das ganze dann z.B. so aussehen:

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

Im `server` müssen wir dann `data_subset`anpassen, sodass auch nach den anderen Variablen gefiltert wird. Dafür müssen wir in `global.R` noch das `shinybutterfly` Paket laden (`devtools::install_github("markdumke/shinybutterfly")`). Hier ersetzen wir jetzt das bisherige `data_subset` durch:

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

Nützlich ist es zusätzlich zur Karte auch noch die Funde in einer Tabelle (ähnlich zu Excel) anzeigen zu lassen. Datentabellen können mit dem R Paket `DT` hinzugefügt werden. In der `ui` ändern wir jetzt das Design, sodass die Shiny App mehrere Tabs nebeneinander enthalten kann (eine `navbarPage`). In einem neuen Tab fügen wir dann eine Datentabelle hinzu, die alle Funde anzeigt, die auch auf der Karte sichtbar sind. 

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

Jetzt haben wir eine App mit zwei Tabs. Im `server` müssen wir nun die Datentabelle erzeugen. Um z.B. Fotos und andere HTML Inhalte darzustellen, muss das Argument `escape = FALSE` gesetzt werden.

```r
  output$table <- DT::renderDataTable(
    data_subset(),
    rownames = FALSE,
    escape = FALSE # to include html, e.g. images in datatable
  )
```

Der Code der App bis hierhin kann [hier](https://gist.github.com/markdumke/d22ddd59cebed89741ee95019c475524) gefunden werden 

Die Shiny App enthält inzwischen bereits zahlreiche nützliche Funktionen. Lese in Teil 2 weiter wie Daten in der App erfasst werden können.

{% include disqus.html %}
