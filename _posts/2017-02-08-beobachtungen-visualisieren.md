---
layout: post
title: Visualisation Schmetterlingsdaten
abstract: Text
author: Markus Dumke
tags: Visualisation Schmetterlingsdaten
comments: true
---

Wissen teilen, auch für andere Leute vielleicht nützlich und interessant.
Du hast eine Excel Tabelle mit Beobachtungsdaten, z.B. Schmetterlingsbeobachtungen, aber weisst nicht, wie du sie schön auf einer Karte darstellen kannst.
Zum Glück gibt es grossartige Pakete wie Shiny oder Leaflet in R, die es sehr einfach machen, eine schöne Visualisation zu basteln.

Im Folgenden werden wir Schritt für Schritt eine solche App gemeinsam bilden.

## Vorbereitungen
Zunächst einmal brauchen wir <a href="https://cran.r-project.org/bin/windows/base/" target="_blank">R</a> und <a href="https://www.rstudio.com/products/rstudio/download/" target="_blank">RStudio</a> (die kostenlose Version reicht aus). 
Installiere diese als erstes auf deinem PC. Lege dann einen neuen Ordner an, in dem wir alle Dateien abspeichern werden. 
Öffne RStudio und lege ein neues Skript an und nenne es "server.R". Dieses wird mal die App, die die Visualization startet. 
Für die grafische Benutzeroberfläche brauchen wir zudem noch ein weiteres Skript "ui.R". Wichtig, diese Dateien müssen genauso heissen.

## Datenaufbereitung
Zunächst speichere deinen Datensatz als csv Datei ab (in Excel Speichern unter, Dateiformat csv auswählen). 
Speichere die Datei in dem Ordner, den wir gerade angelegt haben. Erstelle nun ein neues R Skript, wir nennen es "Datenaufbereitung.R".

Ein Beispiel-"Rohdatensatz" kann hier gefunden werden (Link)
und könnte ungefähr folgendermassen aussehen:

| Datum      | Art                 | Stadium   | Anzahl |
| :--------: | :-----------------: | :--------:| :-----:|
| 02.08.2009 | Gonepteryx rhamni   | Falter    |    5   |
| 04.07.2010 | Aglais io           | Falter    | 18     |
| 04.07.2010 | Polygonia c-album   | Falter    | 3      |
| ...        | ...                 | ...       | ...    |

Um die Daten korrekt darzustellen, sind leider ein paar Vorbereitungen nötig. Zunächst lesen wir die Daten in R ein:

```r
data <- read.csv2("daten.csv", stringsAsFactors = FALSE, encoding = "utf8") # ersetze "daten.csv" durch den Namen des Datensatzs, falls anders.
```

Die Daten sollten Koordinaten enthalten, d.h. zwei Spalten latitude (der Breitengrad) und longitude (der Längengrad). 
Diese sollten als Zahlen vorliegen, ein korrekter Längengrad ist z.B. longitude = 11.3124, ein Breitengrad z.B. latitude = 48.21453.
Falls die Koordinaten in einem anderen Format sind, müssen wir sie erst transformieren. Dafür könnte diese Helferfunktion nützlich sein:

```r
# Koordinaten in richtiges Format bringen
# Funktion extrahiert Koordinaten als Zahlen aus String
# z.B. wird "11,069° E" zu 11.069
extract_coordinates <- function(x) {
  coord <- gsub(x = x, pattern = "[A-Z]", replacement = "")
  coord <- gsub(x = coord, pattern = "° ", replacement = "")
  coord <- gsub(x = coord, pattern = ",", replacement = ".")
  as.numeric(coord)
}

# Koordinaten als Zahlen in Datensatz hinzufügen
data$latitude <- extract_coordinates(data$latitude)
data$longitude <- extract_coordinates(data$longitude)
```

Als nächstes wollen wir automatisch Informationen aus den Koordinaten herausziehen, z.B. die Höhe des Fundpunkts, in welchem Land, Bundesland, Kreis etc. diese liegt.
Dafür benutzen wir folgenden Code: Zunächst müssen wir ein paar Pakete installieren (Pakete enthalten in R nützliche Zusatzfunktionen). 
Das geht einfach mit install.packages("paketname"), wobei wir für paketname dann z.B. raster, sp, lubridate etc. einsetzen müssen.
Wenn wir die Pakete installiert haben, können wir die entsprechenden Zeilen löschen. Danach können wir die Pakete laden und dann die Funktionen aus diesen Paketen nutzen.
Das Paket geonames benötigen wir wenn wir anhand der Koordinaten die Höhe abfragen wollen. 
Dafür ist eine kostenlose Registration auf 
<a href="http://www.geonames.org/login" target="_blank">GeoNames</a> nötig. Setze deinen Username dann in options(geonamesUsername="username") ein.

```r
install.packages("sp")
install.packages("raster")
install.packages("lubridate")
install.packages("geonames") # Zeilen können nach der Installation gelöscht werden

library(sp) # Laden der Pakete
library(raster)
library(lubridate)
library(geonames) # registriere bei geonames um webservices zu nutzen (z.B. Höhenabfrage von Koordinaten)
options(geonamesUsername="username") # ersetze username durch deinen Benutzernamen.
```

Fertig, es kann losgehen.

### Mehr Informationen über das Datum
Extrahiere weitere Informationen aus einem Datum. Es wird vorausgesetzt, dass im Datensatz bereits eine Datumsspalte mit Einträgen im Format "dd.mm.yyyy", also z.B. "24.04.1993" vorliegen.
Diese wandeln wir zunächst in ein sogenanntes date Object in R um und fragen dann Zusatzinformationen wie Tag, Monat, Jahr, Tag im Jahr, Monatstag etc ab. 
Dafür haben wir vorher das lubridate Paket installiert.

```r
data$Datum2 <- dmy(data$Datum)
data$Datum2 <- as.character(data$Datum2)
  
# von Datum im Format "2009-07-04" zurück zu "04.07.2009"
# data$Datum <- format(Datum2, "%d.%m.%Y")
  
# get more information about dates
data$Jahr <- year(data$Datum2)
data$Monat <- month(data$Datum2)
data$yday <- yday(data$Datum2)
data$Monatstag <- mday(data$Datum2)
```

### Bestimme die Höhe aus den Koordinaten
Dafür verwenden wir jetzt unseren geonames Account. Dieser erlaubt uns 2000 Anfragen pro Stunde.

```r
# bestimme Höhe aus Koordinaten
# Abfrage nur für unterschiedliche Koordinaten-Paare nötig. Daher extrahieren wir zunächst alle einzigartigen (latitude, longitude)-Paare.
locations <- unique(data[c("latitude", "longitude")])
altitude <- mapply(GNsrtm3, locations$latitude, locations$longitude)
altitude2 <- unlist(altitude[seq(1, length(altitude), by = 3)])
altitude2[altitude2 < 0] <- 0 # remove artifacts in the data (negative altitude)
  
# match coordinates altitude pairs into the dataframe
# iterator over all locations, finds matches in dataframe and sets altitude to the corresponding value
data$altitude <- NA
for(i in seq_len(nrow(locations))) {
  ind <- which(data$latitude == locations[i, 1] & data$longitude == locations[i, 2])
  data$altitude[ind] <- altitude2[i]
}
```

### Füge geographische Informationen hinzu
Praktisch ist es auch Informationen wie Land, Bundesland, Kreis, Gemeinde automatisch aus den Daten zu extrahieren.

```r
# we will need to download geographic information about countries DE, CH, AUT, IT
# add other ones if you have data from other countries
# gemeinden_de <- getData('GADM', country = 'DE', level = 3)
# gemeinden_ch <- getData('GADM', country = 'CH', level = 3)
# gemeinden_at <- getData('GADM', country = 'AUT', level = 3)

# this takes time, so we save the downloaded files in the folder and load them the next time
# save(gemeinden_de, file = "gemeinden_de")
# save(gemeinden_ch, file = "gemeinden_ch")
# save(gemeinden_at, file = "gemeinden_at")

# Vordefinierte Objekte für Deutschland, Schweiz und Österreich.
load("gemeinden_de")
load("gemeinden_ch")
load("gemeinden_at")

data_geo <- data
coordinates(data_geo) <- c("longitude", "latitude")
  
# use same lat/lon reference system
proj4string(data_geo) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
  
# which Bundesland (if any) contains each sighting and
# store the Bundesland name as an attribute of data
  
which_gemeinde <- over(data_geo, gemeinden)
data$Land <- which_gemeinde$NAME_0
which_gemeinde_ch <- over(data_geo, gemeinden_ch)
data$Land2 <- which_gemeinde_ch$NAME_0
data$Land[!is.na(data$Land2)] <- data$Land2[!is.na(data$Land2)]
which_gemeinde_at <- over(data_geo, gemeinden_at)
data$Land3 <- which_gemeinde_at$NAME_0
data$Land[!is.na(data$Land3)] <- data$Land3[!is.na(data$Land3)]
which_gemeinde_it <- over(data_geo, gemeinden_it)

data$Bundesland <- which_gemeinde$NAME_1
data$Bundesland2 <- which_gemeinde_ch$NAME_1
data$Bundesland[!is.na(data$Bundesland2)] <- data$Bundesland2[!is.na(data$Bundesland2)]
data$Bundesland3 <- which_gemeinde_at$NAME_1
data$Bundesland[!is.na(data$Bundesland3)] <- data$Bundesland3[!is.na(data$Bundesland3)]
data$Bundesland4 <- which_gemeinde_it$NAME_1
data$Bundesland[!is.na(data$Bundesland4)] <- data$Bundesland4[!is.na(data$Bundesland4)]
  
data$Kreis <- which_gemeinde$NAME_2
data$Kreis2 <- which_gemeinde_ch$NAME_2
data$Kreis[!is.na(data$Kreis2)] <- data$Kreis2[!is.na(data$Kreis2)]
data$Kreis3 <- which_gemeinde_at$NAME_2
data$Kreis[!is.na(data$Kreis3)] <- data$Kreis3[!is.na(data$Kreis3)]
 
data$Gemeinde <- which_gemeinde$NAME_3
data$Gemeinde2 <- which_gemeinde_ch$NAME_3
data$Gemeinde[!is.na(data$Gemeinde2)] <- data$Gemeinde2[!is.na(data$Gemeinde2)]
data$Gemeinde3 <- which_gemeinde_at$NAME_3
data$Gemeinde[!is.na(data$Gemeinde3)] <- data$Gemeinde3[!is.na(data$Gemeinde3)]

```

Endlich sind wir fertig und können den fertigen Datensatz abspeichern.

```r
write.csv2(data, "data.csv")
```



Lese weiter in Teil 2 wie wir nun eine Shiny App mit diesen Daten bauen...


[Shiny App](https://github.com/markdumke/lepivis)



The code can be found here: [Github](https://github.com/markdumke/lepivis)
{% include disqus.html %}
