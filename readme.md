# FinanzReport

Dieses Script hilft dabei die Kontobewegungen in Blick zu behalten, in dem es hilft die Aus- und Einnahmen gegenüber zu stellen.

FinanzReport basiert auf einer Klassenerkennung jeder einzelnen Buchung anhand eines Musters.

![](./Example.png =250x)


# Anleitung

Um Einen FinanzReport zu erstellen sind folgende Schritte notwendig:

1. Exportiere von deiner Bank (aktuell Comdirect) alle gewünschten Kontobewegungen per CSV Datei.
2. Lege diese Datei in den Ordner "FinanzReports".
3. Erstelle eine Auswertung mit einem Doppelklick auf "Auswerten.bat".


# Klassen erweitern

Die Klassifizierung der Buchungen ist Textbasiert. Dafür gibt es die Datei "patterns.json".

Es sind bereits Klassen vordefiniert. Jede Klasse besitzt "Keywords", an deren die Klasse dann in jeder Buchung erkannt wird.
Die "Keywords" können beliebig erweitert werden:

```
"patterns": {
      "Versorgung": {
        "keywords": [
          "Edeka",
          "Aldi",
          "Lidl",
          "Rewe",
          "..."
```

Um eine eigene Klasse hinzuzufügen, kann das folgende Beispiel der Datei angehängt werden:

```
"patterns": {
      "Versorgung": {
        "keywords": [
          "Edeka",
          "Aldi",
          "Lidl",
        ],
        "color": "#36a2eb" 
      },
      "MeineKlasse": {
        "keywords": [
          "1",
          "..."
        ],
        "color": "#ffce56"
      }
```