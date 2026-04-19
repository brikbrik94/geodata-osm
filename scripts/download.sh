#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
SOURCES_DIR="$PROJECT_ROOT/sources"
DATA_SRC_DIR="$PROJECT_ROOT/data/src"
MERGED_DIR="$PROJECT_ROOT/data/merged"

# Corporate Identity Utils einbinden
source "$SCRIPT_DIR/ci/utils.sh"

# Tool Check
ARIA2_BIN="$(command -v aria2c 2>/dev/null || true)"
CURL_BIN="$(command -v curl 2>/dev/null || true)"
OSMIUM_BIN="$(command -v osmium 2>/dev/null || true)"

if [ -z "$ARIA2_BIN" ]; then
    log_error "aria2c nicht gefunden. Bitte installieren."
    exit 1
fi

# --- HELFER: MD5 CHECK ---
get_expected_md5() {
    local url="$1"
    [ -z "$CURL_BIN" ] && return 1
    local md5_line
    md5_line=$( "$CURL_BIN" -fsSL "${url}.md5" | head -n1 || true )
    [ -z "$md5_line" ] && return 1
    echo "$md5_line" | awk '{print $1}' | tr '[:upper:]' '[:lower:]'
}

# --- HELFER: OSMIUM VALIDIERUNG ---
validate_pbf() {
    local file="$1"
    [ -z "$OSMIUM_BIN" ] && return 0
    "$OSMIUM_BIN" fileinfo "$file" >/dev/null 2>&1
}

# --- HAUPTSCHLEIFE ---
if [ $# -lt 1 ]; then
    log_error "Verwendung: $0 <Kartenname>"
    exit 1
fi

MAP_NAME="$1"
SOURCE_FILE="$SOURCES_DIR/${MAP_NAME}.txt"
MAP_SRC_DIR="$DATA_SRC_DIR/$MAP_NAME"

if [ ! -f "$SOURCE_FILE" ]; then
    log_error "Quelldatei nicht gefunden: $SOURCE_FILE"
    exit 1
fi

mkdir -p "$MAP_SRC_DIR" "$MERGED_DIR"

log_info "Prüfe Quellen für Karte: $MAP_NAME"

mapfile -t URLS < <(grep -v '^#' "$SOURCE_FILE" | grep '[[:graph:]]')

for url in "${URLS[@]}"; do
    FILENAME=$(basename "$url")
    LOCAL_FILE="$MAP_SRC_DIR/$FILENAME"
    
    log_info "Verarbeite: $FILENAME"
    
    # 1. Download mit SSH-freundlichen Einstellungen
    log_info "  -> Synchronisiere..."
    
    # Aria2c Einstellungen für SSH/Piping:
    # --summary-interval=5: Alle 5 Sekunden ein Status-Update (verhindert Spam)
    # --show-console-readout=false: Deaktiviert die interaktive (kaputte) Zeile
    # --download-result=hide: Keine Ergebnistabelle
    if ! "$ARIA2_BIN" \
        --conditional-get=true \
        --allow-overwrite=true \
        --auto-file-renaming=false \
        --console-log-level=warn \
        --summary-interval=5 \
        --show-console-readout=false \
        --download-result=hide \
        -x 16 -s 16 \
        --dir="$MAP_SRC_DIR" \
        --out="$FILENAME" \
        "$url"; then
        log_error "Download fehlgeschlagen: $url"
        exit 1
    fi

    # 2. Integrität prüfen (Osmium)
    if ! validate_pbf "$LOCAL_FILE"; then
        log_warn "Datei korrupt: $FILENAME. Starte Neu-Download..."
        rm -f "$LOCAL_FILE"
        "$ARIA2_BIN" -x 16 -s 16 --console-log-level=warn --summary-interval=10 --show-console-readout=false --download-result=hide --dir="$MAP_SRC_DIR" --out="$FILENAME" "$url"
        if ! validate_pbf "$LOCAL_FILE"; then
            log_error "Integritätsfehler bei $FILENAME auch nach Neu-Download."
            exit 1
        fi
    fi

    # 3. MD5 prüfen
    if [[ "$url" == *"geofabrik.de"* ]]; then
        EXPECTED_MD5=$(get_expected_md5 "$url")
        if [ -n "$EXPECTED_MD5" ]; then
            ACTUAL_MD5=$(md5sum "$LOCAL_FILE" | awk '{print $1}')
            if [ "$ACTUAL_MD5" != "$EXPECTED_MD5" ]; then
                log_error "MD5 Mismatch für $FILENAME!"
                exit 1
            else
                log_success "  MD5 verifiziert."
            fi
        fi
    fi
done

log_success "Download Phase beendet."
