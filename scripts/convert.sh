#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
MERGED_DIR="$PROJECT_ROOT/data/osm/merged"
OUTPUT_DIR="$PROJECT_ROOT/dist/pmtiles"
BUILD_TMP="$PROJECT_ROOT/data/osm/tmp"
DATA_DIR="$PROJECT_ROOT/data/osm/data"
LOG_DIR="$PROJECT_ROOT/logs"

DOCKER_IMAGE="ghcr.io/onthegomap/planetiler:latest"
USE_SUDO="${USE_SUDO:-0}"

# Corporate Identity Utils einbinden
source "$SCRIPT_DIR/ci/utils.sh"

mkdir -p "$BUILD_TMP" "$DATA_DIR" "$OUTPUT_DIR" "$LOG_DIR"

# Docker Check
DOCKER_BIN="$(command -v docker 2>/dev/null || true)"
if [ -z "$DOCKER_BIN" ]; then
    log_error "Docker nicht gefunden."
    exit 1
fi
DOCKER_CMD="$DOCKER_BIN"
[ "$USE_SUDO" -eq 1 ] && DOCKER_CMD="sudo docker"

# --- HAUPTSCHLEIFE ---
if [ $# -lt 1 ]; then
    log_error "Verwendung: $0 <Kartenname> (z.B. at-plus)"
    exit 1
fi

MAP_NAME="$1"
MERGED_PBF="$MERGED_DIR/${MAP_NAME}.osm.pbf"
PMTILES_NAME="${MAP_NAME}.pmtiles"
# Build-Log im neuen zentralen Log-Ordner
BUILD_LOG="$LOG_DIR/${MAP_NAME}_build_$(date +%Y%m%d_%H%M%S).log"

if [ ! -f "$MERGED_PBF" ]; then
    log_error "Gemergte PBF nicht gefunden: $MERGED_PBF"
    exit 1
fi

log_info "Starte PMTiles Konvertierung für: $MAP_NAME"
log_info "Build-Log: $(basename "$BUILD_LOG")"

# Planetiler starten (Hintergrund)
$DOCKER_CMD run --rm \
  -v "$DATA_DIR":/data \
  -v "$OUTPUT_DIR":/out \
  -v "$MERGED_DIR":/in:ro \
  -v "$BUILD_TMP":/mnt/tmp \
  "$DOCKER_IMAGE" \
  --osm-path="/in/${MAP_NAME}.osm.pbf" \
  --output="/out/$PMTILES_NAME" \
  --tmpdir=/mnt/tmp \
  --force \
  --download=true \
  >> "$BUILD_LOG" 2>&1 &

PID=$!

# Progress anzeigen
if [ -f "$SCRIPT_DIR/planetiler_follow.py" ]; then
    python3 -u "$SCRIPT_DIR/planetiler_follow.py" "$BUILD_LOG" "$PID"
else
    log_info "Warte auf Docker Prozess (PID $PID)..."
    wait $PID
fi

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ] && [ -f "$OUTPUT_DIR/$PMTILES_NAME" ]; then
    SIZE_H=$(du -h "$OUTPUT_DIR/$PMTILES_NAME" | cut -f1)
    log_success "PMTiles erfolgreich erstellt: $OUTPUT_DIR/$PMTILES_NAME ($SIZE_H)"
else
    log_error "Konvertierung fehlgeschlagen (Exit Code: $EXIT_CODE). Siehe Build-Log: $BUILD_LOG"
    exit 1
fi
