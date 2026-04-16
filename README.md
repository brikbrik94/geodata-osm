# geodata-osm (OSM Plugin)

Dieses Repository automatisiert den Build-Prozess für OpenStreetMap-Daten (Österreich & Nachbarn) nach dem neuen Geodata-Updater-Standard. Es dient als Plugin, das nach der Ausführung einen einsatzbereiten `dist/` Ordner für das Deployment bereitstellt.

## Dokumentation
Alle Details zum Betrieb und zum Standard findest du im Ordner `docs/`:

- [**Nutzungsanleitung (usage.md)**](docs/usage.md): Wie du Karten aktualisierst und Quellen verwaltest.
- [**Abhängigkeiten (DEPENDENCIES.md)**](../DEPENDENCIES.md): Liste der benötigten System-Tools.
- [**Corporate Identity (corporate-identity.md)**](docs/corporate-identity.md): Standards für CLI-Ausgaben (Bash & Python).
- [**Plugin-Standard (plugin-standard.md)**](docs/plugin-standard.md): Blueprint für die Erstellung weiterer automatisierter Daten-Plugins.

## Schnellstart
1. Abhängigkeiten installieren (siehe `DEPENDENCIES.md`).
2. `./scripts/init.sh` ausführen.
3. `./update.sh` ausführen.
