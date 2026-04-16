#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
SOURCES_DIR="$PROJECT_ROOT/sources"
DATA_SRC_DIR="$PROJECT_ROOT/data/osm/src"
MERGED_DIR="$PROJECT_ROOT/data/osm/merged"

# Corporate Identity Utils einbinden
source "$SCRIPT_DIR/ci/utils.sh"

# Tool Check
ARIA2_BIN="$(command -v aria2c 2>/dev/null || true)"
CURL_BIN="$(command -v curl 2>/dev/null || true)"

if [ -z "$ARIA2_BIN" ] && [ -z "$CURL_BIN" ]; then
    log_error "Weder aria2c noch curl gefunden."
    exit 1
fi

# --- HAUPTSCHLEIFE ---
if [ $# -lt 1 ]; then
    log_error "Verwendung: $0 <Kartenname> (z.B. at-plus)"
    exit 1
fi

MAP_NAME="$1"
SOURCE_FILE="$SOURCES_DIR/${MAP_NAME}.txt"
MAP_SRC_DIR="$DATA_SRC_DIR/$MAP_NAME"
MERGED_PBF="$MERGED_DIR/${MAP_NAME}.osm.pbf"

if [ ! -f "$SOURCE_FILE" ]; then
    log_error "Quelldatei nicht gefunden: $SOURCE_FILE"
    exit 1
fi

mkdir -p "$MAP_SRC_DIR" "$MERGED_DIR"

log_info "Prüfe Versionen für Karte: $MAP_NAME"

UPDATE_NEEDED=0
if [ ! -f "$MERGED_PBF" ]; then
    log_info "  Keine gemergte PBF gefunden ($MAP_NAME.osm.pbf). Update erforderlich."
    UPDATE_NEEDED=1
fi

# URLs sammeln und auf Änderungen prüfen
declare -A CURRENT_URLS
while IFS= read -r url || [ -n "$url" ]; do
    [[ -z "$url" || "$url" =~ ^# ]] && continue
    
    FILENAME=$(basename "$url")
    URL_CACHE_FILE="$MAP_SRC_DIR/.$FILENAME.url"
    
    # Effektive URL (Redirect) ermitteln
    log_info "  Prüfe $FILENAME..."
    EFFECTIVE_URL=$("$CURL_BIN" -Ls -o /dev/null -w %{url_effective} "$url")
    CURRENT_URLS["$url"]="$EFFECTIVE_URL"
    
    if [ -f "$URL_CACHE_FILE" ]; then
        LAST_URL=$(cat "$URL_CACHE_FILE")
        if [ "$LAST_URL" != "$EFFECTIVE_URL" ]; then
            log_info "    Update gefunden: $EFFECTIVE_URL"
            UPDATE_NEEDED=1
        fi
    else
        log_info "    Neue Datei erkannt."
        UPDATE_NEEDED=1
    fi
done < "$SOURCE_FILE"

if [ "$UPDATE_NEEDED" -eq 0 ]; then
    log_success "Karte $MAP_NAME ist aktuell. Überspringe Download."
    exit 0
fi

log_info "Starte Download-Prozess..."

for url in "${!CURRENT_URLS[@]}"; do
    EFFECTIVE_URL="${CURRENT_URLS[$url]}"
    FILENAME=$(basename "$url")
    LOCAL_FILE="$MAP_SRC_DIR/$FILENAME"
    URL_CACHE_FILE="$MAP_SRC_DIR/.$FILENAME.url"
    
    log_info "Lade: $FILENAME"
    
    if [ -n "$ARIA2_BIN" ]; then
        "$ARIA2_BIN" \
            -x 16 \
            -s 16 \
            --console-log-level=warn \
            --summary-interval=1 \
            --dir="$MAP_SRC_DIR" \
            --out="$FILENAME" \
            --allow-overwrite=true \
            --file-allocation=none \
            "$EFFECTIVE_URL"
        "$CURL_BIN" -L -o "$LOCAL_FILE" "$EFFECTIVE_URL"
    fi
    
    # Validierung und Cache-Update
    if [ -f "$LOCAL_FILE" ] && [ $(stat -c%s "$LOCAL_FILE") -gt 1000 ]; then
        echo "$EFFECTIVE_URL" > "$URL_CACHE_FILE"
        log_success "  Download OK: $FILENAME"
    else
        log_error "  Download fehlgeschlagen: $FILENAME"
        exit 1
    fi
done

log_success "Alle Downloads für $MAP_NAME abgeschlossen."
