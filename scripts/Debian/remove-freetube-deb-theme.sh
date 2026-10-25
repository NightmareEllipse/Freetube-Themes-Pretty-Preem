#!/usr/bin/env bash
set -Eeuo pipefail

FREETUBE_DIR="/opt/FreeTube"
RESOURCES_DIR="$FREETUBE_DIR/resources"
APP_ASAR="$RESOURCES_DIR/app.asar"
BACKUP_ASAR="/opt/FreeTube.backup/resources/app.asar"

APP_STAGE=""

error() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    if [[ -n "$APP_STAGE" && -e "$APP_STAGE" ]]; then
        rm -f -- "$APP_STAGE"
    fi
}
trap cleanup EXIT

if [[ "$EUID" -ne 0 ]]; then
    error "Run this script with sudo:
sudo $0"
fi

[[ -d "$RESOURCES_DIR" ]] || error \
    "Missing FreeTube resources directory: $RESOURCES_DIR"

[[ -f "$BACKUP_ASAR" && ! -L "$BACKUP_ASAR" ]] || error \
    "Original app.asar backup not found or is a symlink: $BACKUP_ASAR"

[[ -s "$BACKUP_ASAR" ]] || error \
    "Original app.asar backup is empty: $BACKUP_ASAR"

if [[ -L "$APP_ASAR" ]]; then
    error "The installed app.asar is a symlink; refusing to replace it: $APP_ASAR"
fi

echo "Stopping FreeTube..."
pkill -x FreeTube 2>/dev/null || true
pkill -x freetube 2>/dev/null || true
sleep 2

echo "Preparing original app.asar..."
APP_STAGE="$(mktemp "$RESOURCES_DIR/.app.asar.restore.XXXXXX")"
install -o root -g root -m 0644 "$BACKUP_ASAR" "$APP_STAGE"

echo "Restoring original app.asar..."
mv -f -- "$APP_STAGE" "$APP_ASAR"
APP_STAGE=""

echo
echo "Original FreeTube app.asar restored."
echo "Backup retained at:"
echo "  /opt/FreeTube.backup"
echo
echo "Start FreeTube with:"
echo "  freetube"

