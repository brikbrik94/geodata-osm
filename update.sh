#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
SOURCES_DIR="$PROJECT_ROOT/sources"

# Hilfsfunktionen
log_header() { echo -e "\n\033[1;35m=== $1 ===\033[0m"; }
log_info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

# --- FUNKTION: UPDATE EINER KARTE ---
update_map() {
    local map_name="$1"
    log_header "Update gestartet für Karte: $map_name"

    # 1. DOWNLOAD
    log_info "SCHRITT 1: Download..."
    if ! bash "$SCRIPT_DIR/download.sh" "$map_name"; then
        log_error "Download für $map_name fehlgeschlagen."
        return 1
    fi

    # 2. MERGE
    log_info "SCHRITT 2: Merge..."
    if ! bash "$SCRIPT_DIR/merge.sh" "$map_name"; then
        log_error "Merge für $map_name fehlgeschlagen."
        return 1
    fi

    # 3. PMTILES
    log_info "SCHRITT 3: PMTiles Konvertierung..."
    if ! bash "$SCRIPT_DIR/convert.sh" "$map_name"; then
        log_error "Konvertierung für $map_name fehlgeschlagen."
        return 1
    fi

    log_success "Update für $map_name erfolgreich."
    return 0
}

# --- HAUPTPRÜFUNG ---
MAPS_TO_UPDATE=()

if [ $# -ge 1 ]; then
    # Spezifische Karte(n) angegeben
    MAPS_TO_UPDATE=("$@")
else
    # Alle Karten in sources/ finden
    log_info "Keine Karte angegeben. Suche nach allen Quellen in sources/*.txt..."
    for f in "$SOURCES_DIR"/*.txt; do
        [ -e "$f" ] || continue
        MAP_NAME=$(basename "$f" .txt)
        MAPS_TO_UPDATE+=("$MAP_NAME")
    done
fi

if [ ${#MAPS_TO_UPDATE[@]} -eq 0 ]; then
    log_error "Keine Karten zum Update gefunden."
    exit 1
fi

# Alle gewählten Karten abarbeiten
FAILED_MAPS=()
for map in "${MAPS_TO_UPDATE[@]}"; do
    if ! update_map "$map"; then
        FAILED_MAPS+=("$map")
    fi
done

# --- FINALE: MANIFEST ---
log_header "SCHRITT 4: Manifest generieren"
if python3 "$SCRIPT_DIR/generate_manifest.py"; then
    log_success "Manifest unter dist/manifest.json aktualisiert."
else
    log_error "Manifest-Generierung fehlgeschlagen."
    exit 1
fi

# Abschlussbericht
if [ ${#FAILED_MAPS[@]} -eq 0 ]; then
    log_header "ALLE UPDATES ERFOLGREICH ABGESCHLOSSEN"
    exit 0
else
    log_header "UPDATES MIT FEHLERN ABGESCHLOSSEN"
    log_error "Fehlgeschlagene Karten: ${FAILED_MAPS[*]}"
    exit 1
fi
