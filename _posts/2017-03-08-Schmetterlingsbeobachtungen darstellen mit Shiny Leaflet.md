---
layout: post
title: Schmetterlingsbeobachtungen darstellen mit Shiny
abstract: Abstract
author: Markus Dumke
tags: Visualisation Schmetterlingsdaten
comments: true
image: schmetterlinge_shiny/karte_calbum.JPG
---

Schon seit ich mich für Schmetterlinge interessiere, habe ich angefangen, Beobachtungen zu erfassen und in ein Notizbuch einzutragen, später dann in eine Excel-Tabelle. Doch ist dieses recht mühsam und bietet einem keine schöne Visualisation der Funde. Daher habe ich diese Shiny App entwickelt, die auf einer Karte die Funde darstellt und auch ermöglicht, neue Funde einfach hinzuzufügen. Im Folgenden möchte ich die Funktionen der App kurz vorstellen. Eine Demo-Version kann hier aufgerufen werden, um zu sehen, wie es interaktiv ausschaut: 
https://markusdumke.shinyapps.io/shinybutterfly/

## Verbreitungskarten

Wenn man Koordinaten hat, ist es nicht schwierig, diese auf einer Karte darzustellen, dafür lässt sich z.B. Leaflet verwenden. Standardmässig werden die Daten auf einer OpenStreetMap Karte dargestellt, doch lassen sich verschiedene Kartenanbieter verwenden, z.B. auch welche mit Satellitenbildern oder Höhenlinien.

Praktisch ist es, die Daten zu filtern, dafür bietet sich eine Sidebar links der Karte an. Hier kann man z.B. bestimmte Arten, Jahre, Beobachtungen in einem bestimmten Bundesland oder einer Gemeinde auswählen. Alle Informationen, die in den Daten enthalten sind, können prinzipiell zum Filtern verwendet werden. Z.B. kann man sich alle Beobachtungen von Vanessa atalanta oberhalb von 2000m in Südtirol zwischen dem 15.August 2010 und dem 12.Mai 2013 anzeigen lassen. Damit sind im Gegensatz z.B. zu Verbreitungskarten, die in Büchern verwendet werden, die Auswahlmöglichkeiten sehr flexibel, die Interaktivität der Karte ermöglicht ein ganz nahes Heranzoomen, aber auch z.B. ein Betrachten der Karte eines ganzen Landes.

![]({{ site.url }}/assets/schmetterlinge_shiny/karte_zitronenfalter.JPG)

Die Punkte können natürlich beliebig gestaltet werden, z.B. die Farbe geändert werden. Praktisch ist es, jedem Punkt ein Popup hinzufügen. Wenn dieser angeklickt wird, lässt sich z.B. eine Zusammenfassung des Funds (Art, Datum, Beobachter etc.) und auch ein Foto anzeigen.

![]({{ site.url }}/assets/schmetterlinge_shiny/karte_calbum.JPG)

## Messtischblatt-Quadranten anzeigen und Daten aggregieren

Die Funde können natürlich einfach aggregiert werden, wie es in vielen Verbreitungskarten in Büchern üblich ist, z.B. auf Messtischblatt (MTB) oder Quadrantenebene. Die Grenzen der Messtischblätter und Quadranten können natürlich auch einfach eingeblendet werden.

![]({{ site.url }}/assets/schmetterlinge_shiny/karte_quadranten.JPG)

## Daten in einer Tabelle anzeigen

Neben der Darstellung in einer Karte ist es auch praktisch, sich die Daten in Tabellenform anzuschauen. Auch das ist z.B. mit DataTable einfach möglich. Ausgewählte Funde, die auf der Karte gerade sichtbar sind, werden dann in der Tabelle angezeigt. Auch die Tabelle lässt sich beliebig anpassen, z.B. kann man nach verschiedenen Spalten sortieren oder einzelne Spalten durchsuchen. Auch Fotos der Beobachtungen können hier angezeigt werden.

![]({{ site.url }}/assets/schmetterlinge_shiny/datentabelle.JPG)

## Flugzeit- und Höhendiagramme

Weiterhin ist es möglich, Flugzeitdiagramme und die Höhenverbreitung der Funde darzustellen, z.B. hier für den Zitronenfalter. Dabei werden die Beobachtungen im Flugzeitdiagramm auf 5 Tagesintervalle zusammengefasst (mit unterschiedlicher Anzahl Tage am Monatsende).

![]({{ site.url }}/assets/schmetterlinge_shiny/diagramme_zitronenfalter.JPG)

## Jahreslisten und phänologische Besonderheiten

Weitere Spielereien sind eine Jahresliste, wo immer der erste und letzte Fund einer Art in einem Jahr aufgeführt werden oder auch die Gesamtzahl beobachteter Falter jeder Art in dem Jahr.

![]({{ site.url }}/assets/schmetterlinge_shiny/jahresliste.JPG)

Man kann sich einfach auch früheste und späteste Sichtungen einer Art anzeigen lassen:
![]({{ site.url }}/assets/schmetterlinge_shiny/erstsichtung.JPG)

Wie viele Arten habe ich in jedem Jahr beobachtet und in welchem Bundesland/Kanton habe ich die meisten Arten oder Falter gesehen? Auch das lässt sich sehr einfach berechnen und darstellen. Das ganze kann natürlich auch für andere Variablen berechnet werden (Monat, Datum, Land, Gemeinde Höhenlage ...)

![]({{ site.url }}/assets/schmetterlinge_shiny/summary.JPG) 

## HTML Dateien einbinden

Weiterhin lassen sich in einer Shiny auch html Dateien sehr einfach einbinden, hier z.B. eine Seite mit einem Artenportrait.
![]({{ site.url }}/assets/schmetterlinge_shiny/html_spini.JPG)


## Zeitleiste hinzufügen

## Neue Daten erfassen

Eine sehr praktische Funktion ist es, Daten neu zu erfassen. Dabei ist es sehr mühsam per Hand Koordinaten herauszusuchen. Viel einfacher ist es neue Datenpunkte einfach per Klick auf die Karte hinzufügen. Das ganze ist sehr einfach: Man trägt die Daten der Beobachtung in die Inputfelder in der Sidebar ein. Wenn man fertig ist, klickt man auf die Karte, dort wo die Beobachtung war. Die Beobachtung wird dann automatisch in einen Datensatz aufgenommen. Wenn man dann alle Bebachtungen erfasst hat, muss man noch einmal auf den Daten Speichern Button klicken. Dadurch wird für die hinzugefügten Koordinaten u.a. die Höhenlage oder in welchem Land/Bundesland/Kreis die Beobachtung liegt, abgefragt und der gesamte Datensatz dann an den alten Datensatz angehängt und alles zusammen als csv Datei abgespeichert, sodass man beim nächsten Start der App alle Daten hat.

![]({{ site.url }}/assets/schmetterlinge_shiny/daten_eingabe.JPG)

{% include disqus.html %}
