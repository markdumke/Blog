---
layout: post
title: Visualisation Schmetterlingsdaten
abstract: Text
author: Markus Dumke
tags: Visualisation Schmetterlingsdaten
image: podalirius_karte.JPG
comments: true
---

Wissen teilen, auch für andere Leute vielleicht nützlich und interessant.
Du hast eine Excel Tabelle mit Beobachtungsdaten, z.B. Schmetterlingsbeobachtungen, aber weisst nicht, wie du sie schön auf einer Karte darstellen kannst.
Zum Glück gibt es grossartige Pakete wie Shiny oder Leaflet in R, die es sehr einfach machen, eine schöne Visualisation zu basteln.

Im Folgenden werden wir Schritt für Schritt eine solche App gemeinsam bilden.

## Vorbereitungen
Zunächst einmal brauchen wir 
<a href="https://cran.r-project.org/bin/windows/base/" target="_blank">R</a> und 
<a href="https://www.rstudio.com/products/rstudio/download/" target="_blank">RStudio</a> 
(die kostenlose Version reicht aus). 
Installiere diese als erstes auf deinem PC. Lege dann einen neuen Ordner an, in dem wir alle Dateien abspeichern werden. 
Öffne RStudio und lege ein neues Skript an und nenne es "server.R". Dieses wird mal die App, die die Visualization startet. 
Für die grafische Benutzeroberfläche brauchen wir zudem noch ein weiteres Skript "ui.R". Wichtig, diese Dateien müssen genauso heissen.

## Datenaufbereitung
Zunächst speichere deinen Datensatz als csv Datei ab (in Excel Speichern unter, Dateiformat csv auswählen). 
Speichere die Datei in dem Ordner, den wir gerade angelegt haben. Erstelle nun ein neues R Skript, wir nennen es "Datenaufbereitung.R".

Ein Beispiel-"Rohdatensatz" kann hier gefunden werden (Link)
und könnte ungefähr folgendermassen aussehen:

|   |Datum      |Art               | Anzahl|Stadium | latitude| longitude|
|:--|:----------|:-----------------|------:|:-------|--------:|---------:|
|1  |31.03.2016 |Gonepteryx rhamni |     15|Falter  | 48.26293|  11.69147|
|3  |31.03.2016 |Aglais urticae    |      3|Falter  | 48.26592|  11.69244|
|5  |31.03.2016 |Aglais io         |     15|Falter  | 48.25689|  11.68959|
|...  |... |...      |    ...|...  | ...|  ...|

Wichtig ist, dass der Datensatz Koordinaten enthält, alles andere ist optional (je nachdem was man erfassen und darstellen will).

Um die Daten korrekt darzustellen, sind leider ein paar Vorbereitungen nötig. Zunächst lesen wir die Daten in R ein (ersetze "daten.csv" durch den Namen des Datensatzs, falls dieser anders heisst):

```r
data <- read.csv2("data.csv", encoding = "utf8")
```

Die Daten sollten Koordinaten enthalten, d.h. zwei Spalten latitude (der Breitengrad) und longitude (der Längengrad). 
Diese sollten als Zahlen vorliegen, ein korrekter Längengrad ist z.B. longitude = 11.3124, ein Breitengrad z.B. latitude = 48.21453.
Falls die Koordinaten in einem anderen Format sind, müssen wir sie erst transformieren. Dafür könnte diese Helferfunktion nützlich sein:

```r
# extract coordinates from string
# e.g "11,069° E" will be 11.069
extract_coordinates <- function(x) {
  coord <- gsub(x = x, pattern = "[A-Z]", replacement = "")
  coord <- gsub(x = coord, pattern = "° ", replacement = "")
  coord <- gsub(x = coord, pattern = ",", replacement = ".")
  as.numeric(coord)
}

# add coordinates to data
data$latitude <- extract_coordinates(data$latitude)
data$longitude <- extract_coordinates(data$longitude)
```

Als nächstes wollen wir automatisch Informationen aus den Koordinaten herausziehen, z.B. die Höhe des Fundpunkts, in welchem Land, Bundesland, Kreis etc. dieser liegt.
Dafür benutzen wir folgenden Code: Zunächst müssen wir ein paar Pakete installieren (Pakete enthalten in R nützliche Zusatzfunktionen). 
Das geht einfach mit install.packages("paketname"), wobei wir für paketname dann z.B. raster, sp, lubridate etc. einsetzen müssen.
Wenn wir die Pakete installiert haben, können wir die entsprechenden Zeilen löschen. Danach können wir die Pakete laden und dann die Funktionen aus diesen Paketen nutzen.

Fertig, es kann losgehen.

### Mehr Informationen über das Datum
Extrahiere weitere Informationen aus einem Datum. Es wird vorausgesetzt, dass im Datensatz bereits eine Datumsspalte mit Einträgen im Format "dd.mm.yyyy", also z.B. "24.04.1993" vorliegen.
Diese wandeln wir zunächst in ein sogenanntes date Object in R um und fragen dann Zusatzinformationen wie Tag, Monat, Jahr, Tag im Jahr, Monatstag etc ab. 
Dafür müssen wir das lubridate Paket laden.

```r
# get date into the format "yyyy-mm-dd"
library(lubridate)
data$Datum2 <- dmy(data$Datum)
data$Datum2 <- as.character(data$Datum2)
  
## from date format "yyyy-mm-dd" back to "dd.mm.yyyy"
# data$Datum <- format(Datum2, "%d.%m.%Y")
  
# extract year, month, yday and mday out of date
data$Jahr <- year(data$Datum2)
data$Monat <- month(data$Datum2)
data$yday <- yday(data$Datum2)
data$Monatstag <- mday(data$Datum2)
```

### Bestimme die Höhe aus den Koordinaten
Das Paket geonames benötigen wir wenn wir anhand der Koordinaten die Höhe abfragen wollen. 
Dafür ist eine kostenlose Registration auf 
<a href="http://www.geonames.org/login" target="_blank">GeoNames</a> nötig. Setze deinen Username dann in options(geonamesUsername="username") ein.
Dafür verwenden wir jetzt unseren geonames Account. Dieser erlaubt uns 2000 Anfragen pro Stunde.

```r
# get altitude values from coordinates
# register by geonames to use webservices
library(geonames) 
options(geonamesUsername="username") # replace username by your geonames username

# getting altitudes only for unique coordinate pairs necessary.
locations <- unique(data[c("latitude", "longitude")])
altitude <- mapply(GNsrtm3, locations$latitude, locations$longitude)
altitude2 <- unlist(altitude[seq(1, length(altitude), by = 3)])

# match coordinates altitude pairs into the dataframe
# iterator over all locations, finds matches in dataframe and 
# sets altitude to the corresponding value
data$altitude <- NA
for(i in seq_len(nrow(locations))) {
  ind <- which(data$latitude == locations[i, 1] & 
                 data$longitude == locations[i, 2])
  data$altitude[ind] <- altitude2[i]
}
```

### Füge geographische Informationen hinzu
Praktisch ist es auch Informationen wie Land, Bundesland, Kreis, Gemeinde automatisch aus den Daten zu extrahieren. Dafür müssen wir zunächst die entsprechenden Pakete laden und geographische Informationen des jeweiligen Landes (hier am Beispiel Deutschland) herunterladen. Dies kann kurz dauern, anschliessend speichern wir diese Datei ab (save), dann können wir sie beim nächsten Mal einfach aus unserem Ordner laden  (load) und müssen sie nicht erneut herunterladen.

```r
# get geographic information out of coordinates
library(sp)
library(raster)

# if you need different countries, 
# change "DE" e.g. by "CH" for Switzerland or "AUT" for Austria
gemeinden_de <- getData('GADM', country = 'DE', level = 3)
save(gemeinden_de, file = "gemeinden_de")

# after we saved the file we can just load it and delete the above lines
load("gemeinden_de")
```


```r
# make SpatialPointsDataFrame
data_geo <- data
coordinates(data_geo) <- c("longitude", "latitude")
  
# use same lat/lon reference system
proj4string(data_geo) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
  
# which Land/Bundesland/Kreis/Gemeinde (if any) contains each sighting and
# store the the name as a column in data
which_gemeinde <- over(data_geo, gemeinden_de)
data$Land <- which_gemeinde$NAME_0
data$Bundesland <- which_gemeinde$NAME_1
data$Kreis <- which_gemeinde$NAME_2
data$Gemeinde <- which_gemeinde$NAME_3
```

Endlich sind wir fertig und können den fertigen Datensatz abspeichern.

```r
write.csv2(data, "data_preprocessed.csv")
```

Lese weiter in Teil 2 wie wir diese Daten nun mithilfe einer Shiny App visualisieren können (Link)

[Shiny App](https://github.com/markdumke/lepivis)

The code can be found here: [Github](https://github.com/markdumke/lepivis)
{% include disqus.html %}
