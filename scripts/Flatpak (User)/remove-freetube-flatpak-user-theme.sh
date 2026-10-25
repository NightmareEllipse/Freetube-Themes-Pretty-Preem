#!/usr/bin/env bash
set -Eeuo pipefail

APP_ID="io.freetubeapp.FreeTube"
ARCH="x86_64"
BRANCH="stable"

FLATPAK_USER_DIR="$HOME/.local/share/flatpak/app/$APP_ID/$ARCH/$BRANCH"
BACKUP_DIR="$HOME/.local/share/FreeTube.backup"
BACKUP_ASAR="$BACKUP_DIR/resources/app.asar"

WORK="$(mktemp -d)"
APP_ASAR_TMP=""

cleanup() {
    rm -rf -- "$WORK"

    if [[ -n "$APP_ASAR_TMP" && -e "$APP_ASAR_TMP" ]]; then
        rm -f -- "$APP_ASAR_TMP"
    fi
}
trap cleanup EXIT

error() {
    echo "ERROR: $*" >&2
    exit 1
}

resolve_app_asar() {
    local candidate="$1"
    local resolved

    [[ -f "$candidate" && ! -L "$candidate" ]] || return 1
    resolved="$(readlink -f -- "$candidate")" || return 1
    [[ -f "$resolved" && ! -L "$resolved" ]] || return 1

    printf '%s\n' "$resolved"
}

find_app_asar() {
    local candidate
    local resolved
    local deployment

    candidate="$FLATPAK_USER_DIR/active/files/freetube/resources/app.asar"
    if resolved="$(resolve_app_asar "$candidate")"; then
        printf '%s\n' "$resolved"
        return 0
    fi

    if [[ -d "$FLATPAK_USER_DIR" ]]; then
        while IFS= read -r -d '' deployment; do
            candidate="$deployment/files/freetube/resources/app.asar"
            if resolved="$(resolve_app_asar "$candidate")"; then
                printf '%s\n' "$resolved"
                return 0
            fi
        done < <(
            find "$FLATPAK_USER_DIR" \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                -print0
        )
    fi

    return 1
}

find_asar_command() {
    local candidate

    for candidate in \
        "$(command -v asar 2>/dev/null || true)" \
        "$HOME/.local/bin/asar" \
        "/usr/local/bin/asar" \
        "/usr/bin/asar"
    do
        if [[ -n "$candidate" && -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

APP_ASAR="$(find_app_asar || true)"
[[ -n "$APP_ASAR" ]] || error \
    "Could not find a regular, non-symlink user-installed FreeTube Flatpak app.asar."

[[ -f "$BACKUP_ASAR" && ! -L "$BACKUP_ASAR" ]] || error \
    "Original app.asar backup not found or is a symlink:
$BACKUP_ASAR"

[[ ! -L "$BACKUP_DIR" ]] || error \
    "Backup directory is a symlink:
$BACKUP_DIR"

[[ -w "$APP_ASAR" ]] || error \
    "The current Flatpak app.asar is not writable:
$APP_ASAR

This script expects a user-installed Flatpak."

ASAR_BIN="$(find_asar_command || true)"
[[ -n "$ASAR_BIN" ]] || error "Could not find the asar command."

echo "Checking the current app.asar..."
"$ASAR_BIN" extract "$APP_ASAR" "$WORK/freetube-app"

DIST_DIR="$WORK/freetube-app/dist"
[[ -d "$DIST_DIR" && ! -L "$DIST_DIR" ]] || error \
    "Could not find a regular dist directory inside app.asar."

RENDERER_CSS=""

while IFS= read -r -d '' file; do
    filename="$(basename "$file")"

    if [[ "$filename" =~ ^renderer\.[[:alnum:]]+\.css$ ]]; then
        [[ -z "$RENDERER_CSS" ]] || error \
            "More than one renderer.<hash>.css file found."
        RENDERER_CSS="$file"
    fi
done < <(
    find "$DIST_DIR" -maxdepth 1 -type f -print0
)

[[ -n "$RENDERER_CSS" && ! -L "$RENDERER_CSS" ]] || error \
    "Could not find a regular renderer.<hash>.css file."

python3 - "$RENDERER_CSS" <<'PY' || error \
    "The current archive does not contain a valid installed theme."
import pathlib
import sys

css = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
begin = "/* FREETUBE-RICING-LAB-THEME-BEGIN */"
end = "/* FREETUBE-RICING-LAB-THEME-END */"

if css.count(begin) != 1 or css.count(end) != 1:
    raise SystemExit(1)

if css.index(begin) >= css.index(end):
    raise SystemExit(1)
PY

echo "Stopping FreeTube..."
flatpak kill "$APP_ID" 2>/dev/null || true
pkill -x FreeTube 2>/dev/null || true
pkill -x freetube 2>/dev/null || true
sleep 2

echo "Restoring original app.asar atomically..."

[[ -f "$APP_ASAR" && ! -L "$APP_ASAR" ]] || error \
    "The target app.asar is no longer a regular, non-symlink file:
$APP_ASAR"

APP_ASAR_TMP="$(mktemp "${APP_ASAR}.restore.XXXXXX")"
install -m 0644 "$BACKUP_ASAR" "$APP_ASAR_TMP"
mv -fT -- "$APP_ASAR_TMP" "$APP_ASAR"
APP_ASAR_TMP=""

echo
echo "Original FreeTube Flatpak app.asar restored."
echo "Backup retained at:"
echo "  $BACKUP_ASAR"
echo
echo "Start FreeTube with:"
echo "  flatpak run $APP_ID"

