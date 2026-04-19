#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"

# CI Utils laden (falls vorhanden)
if [ -f "$SCRIPT_DIR/ci/utils.sh" ]; then
    source "$SCRIPT_DIR/ci/utils.sh"
else
    log_header() { echo -e "\n=== $1 ===\n"; }
    log_info() { echo -e "  ℹ $1"; }
    log_success() { echo -e "  ✔ $1"; }
    log_error() { echo -e "  ✖ $1"; }
fi

log_header "INITIALISIERUNG: GEODATA-OSM"

# 1. Verzeichnisstruktur v1.2
log_info "Erstelle Verzeichnisstruktur..."
mkdir -p "$PROJECT_ROOT/data/src" \
         "$PROJECT_ROOT/data/merged" \
         "$PROJECT_ROOT/data/sources" \
         "$PROJECT_ROOT/work" \
         "$PROJECT_ROOT/logs" \
         "$PROJECT_ROOT/dist/pmtiles" \
         "$PROJECT_ROOT/dist/styles"
log_success "Struktur ist bereit."

# 2. Abhängigkeiten prüfen
log_info "Prüfe System-Abhängigkeiten..."
MISSING=()
for tool in curl aria2c osmium docker python3; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING+=("$tool")
    fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
    log_error "Folgende Tools fehlen: ${MISSING[*]}"
    log_info "Bitte installiere diese via: sudo apt install curl aria2 osmium-tool docker.io python3-venv"
    exit 1
fi
log_success "Alle Basis-Tools gefunden."

# 3. Python Virtual Environment
log_info "Richte Python Virtual Environment ein..."
if [ ! -d "$PROJECT_ROOT/.venv" ]; then
    python3 -m venv "$PROJECT_ROOT/.venv"
fi
source "$PROJECT_ROOT/.venv/bin/activate"
pip install --upgrade pip &> /dev/null
# Hier können wir künftige Python-Abhängigkeiten ergänzen
log_success "Python Umgebung ist bereit."

# 4. Berechtigungen
log_info "Setze Ausführungsrechte für Skripte..."
chmod +x "$PROJECT_ROOT/"*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR/"*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR/"*.py 2>/dev/null || true

log_header "SETUP ERFOLGREICH ABGESCHLOSSEN"
log_info "Du kannst nun ein Update starten mit: ./update.sh <karte>"
