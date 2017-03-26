---
layout: post
title: Visualisation Schmetterlingsdaten - Tutorial
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
Jetzt haben wir bereits eine lauffähige App, die in Rstudio durch Klicken auf **Run App** gestartet werden kann. Es sollte sich ein Fenster öffnen, in dem eine leere Openstreetmap Karte gezeigt wird. Der vollständige Code findet sich hier: [Code](https://gist.github.com/markdumke/c574874f432fb542fb18b5f253d273c3)

## Funde auf der Karte darstellen

Als nächstes wollen wir die Koordinaten der Fundpunkte auf der Karte darstellen. Dafür fügen wir in  `renderLeaflet()` ein `addCircleMarkers()` ein, das die Punkte der Karte hinzufügt.

```r
output$map <- renderLeaflet({
    leaflet(data) %>% addTiles() %>% setView(9.5, 47.5, 9) %>% 
      addCircleMarkers(fillOpacity = 1, opacity = 1)
```

Als nächster Schritt wäre es cool, eine Möglichkeit zu haben, auszuwählen, welche Daten angezeigt werden sollen, z.B. nur eine bestimmte Art oder nur Beobachtungen ab einem bestimmten Jahr.
Dafür fügen wir in `ui.R` eine Sidebar ein, die es uns ermöglicht, die Daten zu filtern. In Shiny sind zahlreiche Inputs möglich, z.B. Buttons, Checkboxes und TextInputs, für mehr Informationen siehe [Shiny Widgets](http://shiny.rstudio.com/gallery/widget-gallery.html).


Zunächst fügen wir einen `selectizeInput` ein, mit dem wir die Art auswählen können.

```r
ui <- fluidPage(
  sidebarPanel(
    selectizeInput("Art", label = "Art", 
                   selected = "Polygonia c-album",
                   choices = levels(data$Art), multiple = TRUE)
              ),
    mainPanel(leafletOutput("Karte", width = "100%", height = "700"))
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

In `server.R` müssen wir dann `data_subset`anpassen, sodass auch nach den anderen Variablen gefiltert wird. Dafür müssen wir in `global.R` noch das `shinybutterfly` Paket laden. In `server.R` ersetzen wir dann das bisherige `data_subset` durch:

```r
  # build subset of data.frame ------------------------------
  # input id and name of variable in dataframe (column name) must be the same!
  data_subset <- reactive({
    textinput_vars <- c("Art", "Stadium", "Land", "Geschlecht", "Beobachter")
    for (i in textinput_vars){
      if (!is_input_empty(input[[i]])) {
        data <- data[data[, i] %in% input[[i]], ]
      }
    }
    sliderinput_vars <- c("altitude", "Jahr")
    for (i in sliderinput_vars){
      data <- data[data[, i] >= input[[i]][1] & data[, i] <= input[[i]][2], ]
    }
    data
  })
```

Die App sollte jetzt etwa so aussehen:

![Shiny App]({{ site.url }}/assets/app3.JPG)
Code: 

### Füge dynamische UI Elemente hinzu
Für input Felder wie Bundesland wäre es sinnvoll, dass die Möglichkeiten von der Auswahl des Lands abhängig sind. Wenn z.B. als Land "Germany"" ausgewählt ist, sind mögliche Inputs bei Bundesland "Bayern" und "Baden-Württemberg". Daher erzeugen wir dieses ui Element mit `renderUI` in `server.R` abhängig davon welches Land ausgewählt ist. Dasselbe machen wir für Kreis und Gemeinde.

In `ui.R`:

```r
 renderUI("Bundesland"),
 renderUI("Kreis"),
 renderUI("Gemeinde"),

```

In `server.R`:

```r
  # build ui: choices of Bundesland depend on which Land is selected
  output$Bundesland <- renderUI({
    choices <- select_choices(data, input, "Bundesland", "Land")
    selectizeInput("Bundesland", label = "Bundesland", selected = FALSE,
      choices = choices, 
      multiple = TRUE)
  })
  
  output$Kreis <- renderUI({
    choices <- select_choices(data, input, "Kreis", c("Land", "Bundesland"))
    selectizeInput("Kreis", label = "Kreis", selected = FALSE,
      choices = choices, 
      multiple = TRUE)
  })
  
  output$Gemeinde <- renderUI({
    choices <- select_choices(data, input, "Gemeinde", c("Land", "Bundesland", "Kreis"))
    selectizeInput("Gemeinde", label = "Gemeinde", selected = FALSE,
      choices = choices, 
      multiple = TRUE)
  })
```

### Satellitenbilder hinzufügen
Manchmal sind auch Satelliten- oder Geländekarten mit Höhenlinien nützlich. Diese können wir recht einfach hinzufügen. Zudem fügen wir noch eine Suche hinzu. Diese Funktionen sind in dem Paket `leaflet.extras`, das wir zunächst noch installieren müssen. <Um das Paket zu installieren, ist ausserdem die neueste Version des Pakets `leaflet` nötig, beides können wir einfach von Github installieren.>

```r
devtools::install_github("bhaskarvk/leaflet.extras")
library(leaflet.extras)
```

Dann ändern wir den Aufruf von `output$map` in `server.R` so:

```r
    output$map <- renderLeaflet({
      leaflet() %>% setView(11, 49, 7) %>% 
      addSearchOSM() %>%
      addTiles(group = "OSM") %>%
      addProviderTiles("Esri.WorldImagery", group = "Satellit") %>%
      addProviderTiles("Esri.WorldTopoMap", group = "Gelände") %>%
      addLayersControl(baseGroup = c("OSM", "Satellit", "Gelände"))
    })
```

Jetzt können wir zwischen verschiedenen Karten wechseln und zudem einfach nach Orten suchen.

### Popups hinzufügen

Nun können wir den Punkten noch einfache Popups hinzufügen. Dafür kann beliebiger HTML Text verwendet werden, z.B. eine Zusammenfassung des jeweiligen Funds und auch Fotos oder Links können dort angezeigt werden. Hier ein Beispiel:

```r
      addCircleMarkers(fillOpacity = 1, opacity = 1, 
        popup = paste(
          data_subset()$Foto, "<br>", 
          data_subset()$Art, "<br>",
          data_subset()$Beobachter, "<br>",
          as.character(data_subset()$Anzahl), 
          data_subset()$Stadium, "<br>",
          data_subset()$Datum)
        )
```

### Messtischblätter und Quadranten anzeigen
Praktisch wäre weiterhin MTBs und Quadranten anzeigen zu lassen. Hier habe ich bereits vordefinierte Objekte erstellt, die mit dem `shinybutterfly` Paket geladen werden.
welche MTBs in dem aktuellen Kartenauschnitt liegen, sodass dann nur diese dargestellt werden (ansonsten kann die App recht langsam werden, wenn alle geplottet werden!).
In `global.R` fügen wir dafür folgenden Code hinzu

```r
getInputwithJS <- '
Shiny.addCustomMessageHandler("findInput",
function(message) {
var inputs = document.getElementsByTagName("input");
Shiny.onInputChange("MTB", inputs[22].checked);
Shiny.onInputChange("Quadranten", inputs[23].checked);
Shiny.onInputChange("MTB_map2", inputs[47].checked);
Shiny.onInputChange("Quadranten_map2", inputs[48].checked);
console.log(inputs);
}
);
'
```

In `ui.R`:
```r

```

```r

```



## Datentabelle einfügen

In einem neuen Tab fügen wir jetzt eine Datentabelle ein, die alle Funde anzeigt, die auch auf der Karte sichtbar sind. Datentabelle können mit dem R Paket `DT` hinzugefügt werden. 


```r

```



The code can be found here: [Github](https://github.com/markdumke/lepivis)
{% include disqus.html %}
