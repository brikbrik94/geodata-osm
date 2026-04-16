#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Hilfsfunktionen
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

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

for dir in "${DIRS[@]}"; do
    mkdir -p "$PROJECT_ROOT/$dir"
    log_info "  Erstellt: $dir"
done

# 2. Abhängigkeiten prüfen
log_info "Prüfe Abhängigkeiten..."

check_tool() {
    if command -v "$1" &> /dev/null; then
        log_success "  [OK] $1 gefunden ($(command -v "$1"))"
    else
        log_warn "  [FEHLT] $1 wurde nicht gefunden!"
    fi
}

check_tool "aria2c"
check_tool "osmium"
check_tool "docker"
check_tool "python3"
check_tool "curl"

# 3. Dummy Source erstellen (falls leer)
if [ ! "$(ls -A "$PROJECT_ROOT/sources"/*.txt 2>/dev/null)" ]; then
    log_info "Erstelle Beispiel-Quelldatei: sources/at.txt"
    echo "https://download.geofabrik.de/europe/austria-latest.osm.pbf" > "$PROJECT_ROOT/sources/at.txt"
fi

log_success "Initialisierung abgeschlossen."
echo -e "\nNächste Schritte:"
echo -e "1. Bearbeite oder erstelle Dateien in sources/*.txt"
echo -e "2. Führe ./update.sh <MAP_NAME> aus"
