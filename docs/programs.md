# Dokumentation der verwendeten Programme

Dieses Projekt nutzt spezialisierte Open-Source-Tools, um OpenStreetMap-Daten effizient zu verarbeiten. Hier ist eine Übersicht, welches Tool für welchen Schritt zuständig ist.

## 1. aria2 (aria2c)
**Zweck:** Hochgeschwindigkeits-Downloads.
**Warum:** Im Gegensatz zu `curl` oder `wget` kann `aria2` mehrere Verbindungen gleichzeitig öffnen und Downloads segmentieren. Da OSM-PBF-Dateien oft mehrere Gigabyte groß sind, spart dies erheblich Zeit.
**Einsatz:** In `scripts/download.sh`.

## 2. Osmium (osmium-tool)
**Zweck:** Manipulation und Zusammenführung von PBF-Dateien.
**Warum:** Osmium ist das Schweizer Taschenmesser für OSM-Daten. Es ist extrem schnell (C++ basiert) und speichereffizient.
**Einsatz:** In `scripts/merge.sh`. Es wird verwendet, um mehrere Teil-Extrakte (z.B. Tirol + Vorarlberg) zu einer einzigen Datei zusammenzuführen, bevor sie konvertiert werden.

## 3. Planetiler
**Zweck:** Konvertierung von OSM (PBF) nach PMTiles.
**Warum:** Planetiler ist aktuell einer der schnellsten Konverter weltweit. Er erstellt Vektor-Kacheln (Vector Tiles) direkt aus PBF-Daten, ohne eine PostgreSQL-Datenbank zu benötigen. Ein kompletter Planet-Export dauert oft weniger als 1 Stunde.
**Einsatz:** Wird über **Docker** in `scripts/convert.sh` ausgeführt. Wir nutzen das offizielle Image `ghcr.io/onthegomap/planetiler`.

## 4. PMTiles (Format)
**Zweck:** Cloud-Native Karten-Speicherformat.
**Warum:** PMTiles ist ein Single-File-Format für Kacheln. Es ermöglicht den Zugriff auf einzelne Kacheln via HTTP Range-Requests, ohne dass ein spezieller Tile-Server (wie GeoServer oder MapServer) im Backend laufen muss. Ein einfacher Webserver oder S3-Bucket reicht aus.

## 5. Python 3
**Zweck:** Metadaten-Management und Orchestrierung.
**Warum:** Python eignet sich hervorragend für die Verarbeitung von JSON und die Erstellung von Manifesten, die vom Frontend gelesen werden können.
**Einsatz:** In `scripts/generate_manifest.py` und `scripts/planetiler_follow.py`.

## 6. Docker
**Zweck:** Isolation und Konsistenz.
**Warum:** Planetiler benötigt Java und viele Ressourcen. Durch Docker müssen wir Java nicht lokal installieren und stellen sicher, dass die Konvertierung in einer definierten Umgebung stattfindet.
