---
layout: post
title: Visualisation Schmetterlingsdaten
abstract: Text
author: Markus Dumke
tags: Visualisation Schmetterlingsdaten
comments: true
---

Wissen teilen, auch f?r andere Leute vielleicht n?tzlich und interessant.
Du hast eine Excel Tabelle mit Beobachtungsdaten, z.B. Schmetterlingsbeobachtungen, aber weisst nicht, wie du sie sch?n auf einer Karte darstellen kannst.
Zum Gl?ck gibt es grossartige Pakete wie Shiny oder Leaflet in R, die es sehr einfach machen, eine sch?ne Visualisation zu basteln.


Im Folgenden werden wir Schritt f?r Schritt eine solche App gemeinsam bilden.
## Vorbereitungen
Zun?chst einmal brauchen wir [R](https://cran.r-project.org/bin/windows/base/) und [RStudio](https://www.rstudio.com/products/rstudio/download/). 
Installiere diese als erstes auf deinem PC. Lege dann einen neuen Ordner an, in dem wir alle Dateien abspeichern werden. 
?ffne RStudio und lege ein neues Skript an und nenne es "server.R". Dieses wird mal die App, die die Visualization startet. 
F?r die grafische Benutzeroberfl?che brauchen wir zudem noch ein weiteres Skript "ui.R". Wichtig, diese Dateien m?ssen genauso heissen.

## Datenaufbereitung
Zun?chst speichere deinen Daten als csv Datei ab (in Excel Speichern unter, Dateiformat csv ausw?hlen). 
Speichere die Datei in demselben Ordner, den wir gerade angelegt haben. Erstelle nun ein neues R Skript, wir nennen es "Datenaufbereitung.R".

Ein Beispiel-"Rohdatensatz" kann hier gefunden werden: 
Um die Daten korrekt darzustellen, sind leider ein paar Vorbereitungen n?tig. Zun?chst lesen wir die Daten in R ein:
```r
data <- read.csv2("daten.csv", stringsAsFactors = FALSE, encoding = "utf8") # ersetze "daten.csv" durch den Namen des Datensatzs, falls anders.
```

Die Daten sollten Koordinaten enthalten, d.h. zwei Spalten latitude (der Breitengrad) und longitude (der L?ngengrad). 
Diese sollten als Zahlen vorliegen, ein korrekter L?ngengrad ist z.B. longitude = 11.3124, ein Breitengrad z.B. latitude = 48.21453.
Falls die Koordinaten in einem anderen Format sind, m?ssen wir sie erst transformieren. Daf?r k?nnten diese Helferfunktionen n?tzlich sein:

```r
# Koordinaten in richtiges Format bringen
# Funktion extrahiert Koordinaten als Zahlen aus String
# z.B. "11,069? E" wird zu 11.069
extract_coordinates <- function(x) {
  coord <- sub(x = x, pattern = "[A-Z]", replacement = "")
  coord <- sub(x = coord, pattern = "? ", replacement = "")
  coord <- sub(x = coord, pattern = ",", replacement = ".")
  as.numeric(coord)
}

# Koordinaten als Zahlen in Datensatz hinzuf?gen
data$latitude <- extract_coordinates(data$Breite)
data$longitude <- extract_coordinates(data$L?nge)
```

Als n?chstes wollen wir automatisch Informationen aus den Koordinaten herausziehen, z.B. die H?he des Fundpunkts, in welchem Land, Bundesland, Kreis etc. diese liegt.
Daf?r benutzen wir folgenden Code: Zun?chst m?ssen wir ein paar Pakete installieren (Pakete enthalten in R n?tzliche Zusatzfunktionen). 
Das geht einfach mit install.packages("paketname"), wobei wir f?r paketname dann z.B. raster, sp, lubridate etc. einsetzen m?ssen.
Wenn wir die Pakete installiert haben, k?nnen wir die entsprechenden Zeilen l?schen. Danach k?nnen wir die Pakete laden und dann die Funktionen aus diesen Paketen nutzen.
Das Paket geonames ben?tigen wir wenn wir anhand der Koordinaten die H?he abfragen wollen. 
Daf?r ist eine kostenlose Registration auf [GeoNames](http://www.geonames.org/login) n?tig. Setze deinen Username dann in options(geonamesUsername="username") ein.

```r
install.packages("sp")
install.packages("raster")
install.packages("lubridate")
install.packages("geonames") # Zeilen k?nnen nach der Installation gel?scht werden

library(sp) # Laden der Pakete
library(raster)
library(lubridate)
library(geonames) # registriere bei geonames um webservices zu nutzen (z.B. H?henabfrage von Koordinaten)
options(geonamesUsername="username") # ersetze username durch deinen Benutzernamen.
```

Fertig, es kann losgehen.

### Mehr Informationen ?ber das Datum
Extrahiere weitere Informationen aus einem Datum. Es wird vorausgesetzt, dass im Datensatz bereits eine Datumsspalte mit Eintr?gen im Format "dd.mm.yyyy", also z.B. "24.04.1993" vorliegen.
Diese wandeln wir zun?chst in ein sogenanntes date Object in R um und fragen dann Zusatzinformationen wie Tag, Monat, Jahr, Tag im Jahr, Monatstag etc ab. 
Daf?r haben wir vorher das lubridate Paket installiert.

```r
data$Datum2 <- dmy(data$Datum)
data$Datum2 <- as.character(data$Datum2)
  
# von Datum im Format "2009-07-04" zur?ck zu "04.07.2009"
# data$Datum <- format(Datum2, "%d.%m.%Y")
  
# get more information about dates
data$Jahr <- year(data$Datum2)
data$Monat <- month(data$Datum2)
data$yday <- yday(data$Datum2)
data$Monatstag <- mday(data$Datum2)
```

### Bestimme die H?he aus den Koordinaten
Daf?r verwenden wir jetzt unseren geonames Account. Dieser erlaubt uns 2000 Anfragen pro Stunde.
```r
# bestimme H?he aus Koordinaten
# Abfrage nur f?r unterschiedliche Koordinaten-Paare n?tig. Daher extrahieren wir zun?chst alle einzigartigen (latitude, longitude)-Paare.
locations <- unique(data[c("latitude", "longitude")])
altitude <- mapply(GNsrtm3, locations$latitude, locations$longitude)
altitude2 <- unlist(altitude[seq(1, length(altitude), by = 3)])
altitude2[altitude2 < 0] <- 0 # remove artifacts in the data (negative altitude)
  
# match coordinates altitude pairs into the dataframe
# iterator over all locations, finds matches in dataframe and sets altitude to the corresponding value
df$altitude <- NA
for(i in seq_len(nrow(locations))) {
  ind <- which(df$latitude == locations[i, 1] & df$longitude == locations[i, 2])
  df$altitude[ind] <- altitude2[i]
}
```


```r
# we will need to download geographic information about countries DE, CH, AUT, IT
# add other ones if you have data from other countries
# gemeinden_de <- getData('GADM', country = 'DE', level = 3)
# gemeinden_ch <- getData('GADM', country = 'CH', level = 3)
# gemeinden_at <- getData('GADM', country = 'AUT', level = 3)
# gemeinden_it <- getData('GADM', country = 'IT', level = 3)

# this takes time, so we save the downloaded files in the folder and load them the next time
# save(gemeinden_de, file = "gemeinden_de")
# save(gemeinden_ch, file = "gemeinden_ch")
# save(gemeinden_at, file = "gemeinden_at")
# save(gemeinden_it, file = "gemeinden_it")

# Vordefinierte Objekte f?r Deutschland, Schweiz und ?sterreich.
load("gemeinden_de")
load("gemeinden_ch")
load("gemeinden_at")

df_geo <- df
coordinates(df_geo) <- c("longitude", "latitude")
  
  # use same lat/lon reference system
  proj4string(df_geo) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
  
  # which Bundesland (if any) contains each sighting and
  # store the Bundesland name as an attribute of df
  
  which_gemeinde <- over(df_geo, gemeinden)
  df$Land <- which_gemeinde$NAME_0
  which_gemeinde_ch <- over(df_geo, gemeinden_ch)
  df$Land2 <- which_gemeinde_ch$NAME_0
  df$Land[!is.na(df$Land2)] <- df$Land2[!is.na(df$Land2)]
  which_gemeinde_at <- over(df_geo, gemeinden_at)
  df$Land3 <- which_gemeinde_at$NAME_0
  df$Land[!is.na(df$Land3)] <- df$Land3[!is.na(df$Land3)]
  which_gemeinde_it <- over(df_geo, gemeinden_it)
  df$Land4 <- which_gemeinde_it$NAME_0
  df$Land[!is.na(df$Land4)] <- df$Land4[!is.na(df$Land4)]
  
  df$Bundesland <- which_gemeinde$NAME_1
  df$Bundesland2 <- which_gemeinde_ch$NAME_1
  df$Bundesland[!is.na(df$Bundesland2)] <- df$Bundesland2[!is.na(df$Bundesland2)]
  df$Bundesland3 <- which_gemeinde_at$NAME_1
  df$Bundesland[!is.na(df$Bundesland3)] <- df$Bundesland3[!is.na(df$Bundesland3)]
  df$Bundesland4 <- which_gemeinde_it$NAME_1
  df$Bundesland[!is.na(df$Bundesland4)] <- df$Bundesland4[!is.na(df$Bundesland4)]
  
  df$Kreis <- which_gemeinde$NAME_2
  df$Kreis2 <- which_gemeinde_ch$NAME_2
  df$Kreis[!is.na(df$Kreis2)] <- df$Kreis2[!is.na(df$Kreis2)]
  df$Kreis3 <- which_gemeinde_at$NAME_2
  df$Kreis[!is.na(df$Kreis3)] <- df$Kreis3[!is.na(df$Kreis3)]
  df$Kreis4 <- which_gemeinde_it$NAME_2
  df$Kreis[!is.na(df$Kreis4)] <- df$Kreis4[!is.na(df$Kreis4)]
  
  df$Gemeinde <- which_gemeinde$NAME_3
  df$Gemeinde2 <- which_gemeinde_ch$NAME_3
  df$Gemeinde[!is.na(df$Gemeinde2)] <- df$Gemeinde2[!is.na(df$Gemeinde2)]
  df$Gemeinde3 <- which_gemeinde_at$NAME_3
  df$Gemeinde[!is.na(df$Gemeinde3)] <- df$Gemeinde3[!is.na(df$Gemeinde3)]
  df$Gemeinde4 <- which_gemeinde_it$NAME_3
  df$Gemeinde[!is.na(df$Gemeinde4)] <- df$Gemeinde4[!is.na(df$Gemeinde4)]
```








[Shiny App](https://github.com/markdumke/lepivis)



The code can be found here: [Github](https://github.com/markdumke/lepivis)

<hr>

{% include disqus.html %}
