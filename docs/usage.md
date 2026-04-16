# Nutzungsanleitung: geodata-osm

Dieses Repository dient dazu, OpenStreetMap (OSM) Daten automatisiert herunterzuladen, zu mergen und in das effiziente PMTiles-Format für Web-Karten zu konvertieren.

## 1. Quick Start
1. Repository klonen.
2. `./scripts/init.sh` ausführen, um die Ordnerstruktur zu erstellen und Abhängigkeiten zu prüfen.
3. `./update.sh` ausführen, um alle definierten Karten zu aktualisieren.

## 2. Quellen verwalten
Die Quellen für die PBF-Downloads werden im Ordner `sources/` als einfache Textdateien (`.txt`) abgelegt.
- **Dateiname:** Der Name der Textdatei (ohne Endung) bestimmt die ID der Karte (z.B. `at.txt` -> `at`).
- **Inhalt:** Jede Zeile muss eine URL zu einer `.osm.pbf` Datei enthalten (z.B. von Geofabrik).
- **Zusammenführung:** Wenn mehrere URLs in einer Datei stehen, werden diese automatisch mit `osmium` gemergt.

## 3. Der Update-Prozess
Das zentrale Steuerelement ist `./update.sh`. Es durchläuft für jede Karte folgende Schritte:
1. **Download:** Lädt nur neue Versionen herunter (basiert auf URL-Redirect-Checks).
2. **Merge:** Kombiniert mehrere PBFs zu einer stabilen Arbeitsdatei.
3. **Konvertierung:** Nutzt `planetiler` im Docker-Container für eine performante Erstellung von `.pmtiles`.
4. **Manifest:** Generiert eine `dist/manifest.json`, die vom Hauptsystem für das Deployment genutzt wird.

## 4. Ausgabe (dist/)
Das fertige Ergebnis liegt im Ordner `dist/`:
- `pmtiles/`: Die optimierten Kartendaten.
- `styles/`: Passende MapLibre Style-Dateien.
- `manifest.json`: Deployment-Metadaten.
