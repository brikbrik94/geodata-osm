#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
DATA_SRC_DIR="$PROJECT_ROOT/data/osm/src"
MERGED_DIR="$PROJECT_ROOT/data/osm/merged"

# Corporate Identity Utils einbinden
source "$SCRIPT_DIR/ci/utils.sh"

# Tool Check
if ! command -v osmium &> /dev/null; then
    log_error "Osmium Tool ('osmium') nicht gefunden."
    exit 1
fi

# --- HAUPTSCHLEIFE ---
if [ $# -lt 1 ]; then
    log_error "Verwendung: $0 <Kartenname>"
    exit 1
fi

MAP_NAME="$1"
MAP_SRC_DIR="$DATA_SRC_DIR/$MAP_NAME"
MERGED_PBF="$MERGED_DIR/${MAP_NAME}.osm.pbf"

mkdir -p "$MERGED_DIR"

log_info "Starte Merge für Karte: $MAP_NAME"

# Suche nach PBF-Dateien im Source-Ordner
mapfile -t PBF_FILES < <(find "$MAP_SRC_DIR" -maxdepth 1 -name "*.osm.pbf" | sort)

if [ ${#PBF_FILES[@]} -eq 0 ]; then
    if [ -f "$MERGED_PBF" ]; then
        log_success "Keine Quelldateien gefunden, aber gemergte Datei existiert bereits."
        exit 0
    else
        log_error "Keine Quelldateien in $MAP_SRC_DIR gefunden!"
        exit 1
    fi
fi

if [ ${#PBF_FILES[@]} -eq 1 ]; then
    log_info "Nur eine Quelldatei gefunden. Kopiere direkt..."
    cp -f "${PBF_FILES[0]}" "$MERGED_PBF"
else
    log_info "Merge von ${#PBF_FILES[@]} Dateien zu $MERGED_PBF..."
    # Einfacher Merge ohne Sort (spart massiv RAM)
    if osmium merge "${PBF_FILES[@]}" -o "$MERGED_PBF" --overwrite; then
        log_success "Merge erfolgreich abgeschlossen."
    else
        log_error "Fehler beim Mergen."
        exit 1
    fi
fi

# Abschluss-Check
if [ -f "$MERGED_PBF" ] && [ $(stat -c%s "$MERGED_PBF") -gt 1000 ]; then
    log_info "Lösche Quelldateien in $MAP_SRC_DIR..."
    find "$MAP_SRC_DIR" -maxdepth 1 -name "*.osm.pbf" -delete
    log_success "Bereinigung abgeschlossen."
else
    log_error "Merge-Ergebnis ungültig."
    exit 1
fi
