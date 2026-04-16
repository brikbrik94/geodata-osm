#!/bin/bash
set -euo pipefail

# --- KONFIGURATION ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"

# Corporate Identity Utils einbinden
source "$SCRIPT_DIR/ci/utils.sh"

log_header "ABHÄNGIGKEITS-CHECK"

DEPENDENCIES=("curl" "aria2c" "osmium" "docker" "python3")
MISSING=()

for tool in "${DEPENDENCIES[@]}"; do
    if command -v "$tool" &> /dev/null; then
        log_success "Tool gefunden: $tool"
    else
        log_error "Tool fehlt: $tool"
        MISSING+=("$tool")
    fi
done

# Docker Berechtigung prüfen
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        log_success "Docker Zugriff: OK"
    else
        log_warn "Docker Zugriff: FEHLT (sudo erforderlich?)"
    fi
fi

# Abschluss
if [ ${#MISSING[@]} -eq 0 ]; then
    log_success "Alle Abhängigkeiten sind erfüllt."
    exit 0
else
    log_error "Fehlende Abhängigkeiten: ${MISSING[*]}"
    log_info "Bitte installiere die fehlenden Tools gemäß DEPENDENCIES.md"
    exit 1
fi
