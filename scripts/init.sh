#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"

# Corporate Identity Utils einbinden
source "$SCRIPT_DIR/ci/utils.sh"

log_header "INITIALISIERUNG"
log_info "Initialisiere Projektstruktur für geodata-osm..."

# 1. Verzeichnisse erstellen
DIRS=(
    "data/osm/src"
    "data/osm/merged"
    "data/osm/tmp"
    "data/osm/data"
    "data/osm/stats"
    "dist/pmtiles"
    "dist/styles"
    "sources"
    "scripts"
    "styles"
    "legacy"
)

log_step 1 3 "Verzeichnisstruktur"
for dir in "${DIRS[@]}"; do
    mkdir -p "$PROJECT_ROOT/$dir"
    log_info "  Erstellt: $dir"
done

# 2. Abhängigkeiten prüfen
log_step 2 3 "Abhängigkeiten prüfen"
if ! bash "$SCRIPT_DIR/check_dependencies.sh"; then
    log_warn "Einige Abhängigkeiten fehlen. Siehe oben."
fi

# 3. Dummy Source erstellen (falls leer)
log_step 3 3 "Quelldateien vorbereiten"
if [ ! "$(ls -A "$PROJECT_ROOT/sources"/*.txt 2>/dev/null)" ]; then
    log_info "Erstelle Beispiel-Quelldatei: sources/at.txt"
    echo "https://download.geofabrik.de/europe/austria-latest.osm.pbf" > "$PROJECT_ROOT/sources/at.txt"
    log_success "Standard-Quellen erstellt."
else
    log_info "Existierende Quellen gefunden."
fi

log_success "Initialisierung abgeschlossen."
log_info "Nächste Schritte:"
echo -e "  1. Bearbeite oder erstelle Dateien in sources/*.txt"
echo -e "  2. Führe ./update.sh <MAP_NAME> aus"
