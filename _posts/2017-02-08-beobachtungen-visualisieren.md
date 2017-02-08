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
Zunächst einmal brauchen wir [R](https://cran.r-project.org/bin/windows/base/) und [RStudio](https://www.rstudio.com/products/rstudio/download/). 
Installiere diese als erstes auf deinem PC. Lege dann einen neuen Ordner an, in dem wir alle Dateien abspeichern werden. 
Öffne RStudio und lege ein neues Skript an und nenne es "server.R". Dieses wird mal die App, die die Visualization startet. 
Für die grafische Benutzeroberfläche brauchen wir zudem noch ein weiteres Skript "ui.R". Wichtig, diese Dateien müssen genauso heissen.

<a href="https://cran.r-project.org/bin/windows/base/" target="_blank">R</a>


{% include disqus.html %}
