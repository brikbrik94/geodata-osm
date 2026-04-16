# Roadmap: Migration OSM-Stack zu Plugin-Struktur

Dieses Dokument dient als interaktive Roadmap für den Umbau des OSM-Stacks (Österreich + Nachbarn) in ein eigenständiges Plugin-Repository gemäß dem neuen Geodata-Updater-Standard.

## 1. Zukünftiger Standard (Ziel)
Das Ziel ist ein eigenständiges Repository, das nach Ausführung seiner Build-Logik einen `dist/` Ordner bereitstellt, der vollautomatisch vom Haupt-System deployed werden kann.

### Erwartete Verzeichnisstruktur im Zielzustand:
```text
geodata-osm/
├── update.sh                 # Zentraler Einstiegspunkt (koordininiert alles)
├── scripts/                  # Übernommene und verbesserte Skripte
│   ├── download.sh           # aria2c Download & Integritätscheck
│   ├── merge.sh              # osmium merge Logik
│   ├── convert.sh            # planetiler Docker-Logik
│   └── planetiler_follow.py  # Monitoring
├── sources/                  # Definitionen der PBF-Quellen (at.txt, at-plus.txt)
├── styles/                   # Vorlagen für MapLibre Stylesheets
└── dist/                     # Das fertige Ausgabeverzeichnis (vom Hauptsystem genutzt)
    ├── manifest.json         # Deployment-Steuerung (Pflicht!)
    ├── pmtiles/              # Fertige .pmtiles Dateien
    └── styles/               # Finalisierte style.json Dateien
```

## 2. Aktueller Status (Vorhandener Code)
Folgende Skripte wurden aus dem alten System in den Ordner `code/` kopiert und warten auf ihre Migration:
*   `download_osm.sh`
*   `run_merge.sh`
*   `convert_osm_pmtiles.sh`
*   `planetiler_follow.py`
*   `utils.sh`

## 3. Interaktiver Fahrplan (Schritt für Schritt)

Wir werden diese Schritte interaktiv durchgehen, um Verbesserungen (z.B. bessere Fehlerbehandlung, Logging) einzubauen.

### Schritt 1: Struktur-Vorbereitung
*   [x] Ordner `code/` in `scripts/` umbenennen.
*   [x] Basis-Verzeichnisse (`dist/`, `dist/pmtiles/`, `dist/styles/`) erstellen.
*   [x] Eine leere `update.sh` als Skelett anlegen.

### Schritt 2: Download-Logik (Modernisierung)
*   [x] `download_osm.sh` anpassen:
    *   Nutzt lokale `sources/*.txt`.
    *   Speichert PBFs in einem lokalen Cache-Ordner (nicht direkt in `dist`).
    *   Interaktive Entscheidung: Robustes automatisches Retry-Verhalten implementiert.

### Schritt 3: Merge & Validierung
*   [x] `run_merge.sh` anpassen:
    *   Einbau einer PBF-Validierung mit `osmium` vor dem Merge (verhindert späte Planetiler-Fehler).
    *   Ausgabe des gemergten PBF in einen temporären Arbeitsordner.

### Schritt 4: Planetiler Konvertierung
*   [x] `convert_osm_pmtiles.sh` anpassen:
    *   Ausgabe der `.pmtiles` direkt nach `dist/pmtiles/`.
    *   Sicherstellen, dass `planetiler_follow.py` korrekt eingebunden ist.

### Schritt 5: Manifest & Styles
*   [x] Erstellen der `manifest.json` in `dist/`.
*   [x] Kopieren und Vorbereiten der `osm-style.json` in `dist/styles/`.

---
*Status: Diese Roadmap wurde am 11. April 2026 erfolgreich abgeschlossen. Gemini hat alle Skripte auf die neue Plugin-Struktur migriert.*
