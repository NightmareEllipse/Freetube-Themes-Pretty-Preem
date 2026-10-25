#!/usr/bin/env bash
set -Eeuo pipefail

error() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

if [[ "$EUID" -ne 0 ]]; then
    printf 'ERROR: Run this script with sudo:\n\n  sudo %s\n' "$0" >&2
    exit 1
fi

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    [[ -n "$USER_HOME" && -d "$USER_HOME" ]] || error \
        "Could not determine the home directory for user: $SUDO_USER"
else
    USER_HOME="${HOME:-}"
    [[ -n "$USER_HOME" && -d "$USER_HOME" ]] || error \
        "Could not determine the current user's home directory."
fi

FREETUBE_DIR="/opt/FreeTube"
APP_ASAR="$FREETUBE_DIR/resources/app.asar"

THEME_DIR="$USER_HOME/.scripts/Freetube Themes/000 Active"
THEME_IMG_DIR="$THEME_DIR/imgs"

BACKUP_DIR="/opt/FreeTube.backup"
BACKUP_ASAR="$BACKUP_DIR/resources/app.asar"

WORK="$(mktemp -d)"
BACKUP_STAGE=""
BACKUP_OLD=""
APP_STAGE=""

cleanup() {
    local exit_status=$?

    rm -rf -- "$WORK"

    if [[ -n "$APP_STAGE" && -e "$APP_STAGE" ]]; then
        rm -f -- "$APP_STAGE"
    fi

    if [[ -n "$BACKUP_STAGE" && -e "$BACKUP_STAGE" ]]; then
        rm -rf -- "$BACKUP_STAGE"
    fi

    # If the old backup was moved aside but the replacement was not
    # installed, put the old backup back where it was.
    if [[ -n "$BACKUP_OLD" && -e "$BACKUP_OLD" ]]; then
        if [[ ! -e "$BACKUP_DIR" ]]; then
            mv -- "$BACKUP_OLD" "$BACKUP_DIR" || {
                printf 'WARNING: Could not restore the previous backup.\n' >&2
                printf 'It remains at: %s\n' "$BACKUP_OLD" >&2
            }
        else
            printf 'WARNING: A previous backup was preserved at:\n  %s\n' \
                "$BACKUP_OLD" >&2
        fi
    fi

    exit "$exit_status"
}
trap cleanup EXIT

[[ -f "$APP_ASAR" ]] || error \
    "Missing app.asar: $APP_ASAR"

[[ -d "$THEME_DIR" && ! -L "$THEME_DIR" ]] || error \
    "Missing theme directory or it is a symlink: $THEME_DIR"

[[ -d "$THEME_IMG_DIR" && ! -L "$THEME_IMG_DIR" ]] || error \
    "Missing theme image directory or it is a symlink: $THEME_IMG_DIR"

command -v python3 >/dev/null 2>&1 || error \
    "python3 is required but was not found."

mapfile -d '' THEME_FILES < <(
    find "$THEME_DIR" \
        -maxdepth 1 \
        -type f \
        -iname '*.css' \
        -print0 |
    sort -z
)

[[ "${#THEME_FILES[@]}" -eq 1 ]] || error \
    "Expected exactly one CSS file in: $THEME_DIR"

for theme_file in "${THEME_FILES[@]}"; do
    [[ ! -L "$theme_file" ]] || error \
        "Theme CSS file must not be a symlink: $theme_file"

    if [[ "$(wc -c < "$theme_file")" -lt 100 ]]; then
        error "Theme CSS file is suspiciously small: $theme_file"
    fi
done

IMAGE_SYMLINK="$(find "$THEME_IMG_DIR" -type l -print -quit)"
[[ -z "$IMAGE_SYMLINK" ]] || error \
    "Theme image directory contains a symlink: $IMAGE_SYMLINK"

ASAR_BIN=""

for candidate in \
    "$(command -v asar 2>/dev/null || true)" \
    "/usr/local/bin/asar" \
    "/usr/bin/asar" \
    "$USER_HOME/.local/bin/asar"
do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
        ASAR_BIN="$candidate"
        break
    fi
done

[[ -n "$ASAR_BIN" ]] || error \
    "Could not find the asar command."

printf 'Using FreeTube: %s\n' "$FREETUBE_DIR"
printf 'Using app.asar: %s\n' "$APP_ASAR"
printf 'Using asar: %s\n' "$ASAR_BIN"
printf 'Using theme directory: %s\n' "$THEME_DIR"
printf 'Using theme images: %s\n\n' "$THEME_IMG_DIR"

printf 'Stopping FreeTube...\n'
pkill -x FreeTube 2>/dev/null || true
pkill -x freetube 2>/dev/null || true
sleep 2

printf 'Extracting app.asar...\n'
"$ASAR_BIN" extract "$APP_ASAR" "$WORK/freetube-app"

DIST_DIR="$WORK/freetube-app/dist"
[[ -d "$DIST_DIR" ]] || error \
    "Could not find dist directory inside app.asar: $DIST_DIR"

RENDERER_CSS=""

while IFS= read -r -d '' file; do
    filename="$(basename "$file")"

    if [[ "$filename" =~ ^renderer\.[[:alnum:]]+\.css$ ]]; then
        [[ -z "$RENDERER_CSS" ]] || error \
            "More than one renderer CSS file was found in: $DIST_DIR"
        RENDERER_CSS="$file"
    fi
done < <(
    find "$DIST_DIR" -maxdepth 1 -type f -print0
)

[[ -n "$RENDERER_CSS" ]] || error \
    "Could not find renderer.<hash>.css inside: $DIST_DIR"

RENDERER_FILENAME="$(basename "$RENDERER_CSS")"
printf 'Found renderer CSS: %s\n' "$RENDERER_FILENAME"

THEME_BEGIN="/* FREETUBE-RICING-LAB-THEME-BEGIN */"
THEME_END="/* FREETUBE-RICING-LAB-THEME-END */"

HAS_BEGIN=0
HAS_END=0

grep -qF "$THEME_BEGIN" "$RENDERER_CSS" && HAS_BEGIN=1 || true
grep -qF "$THEME_END" "$RENDERER_CSS" && HAS_END=1 || true

if [[ "$HAS_BEGIN" -ne "$HAS_END" ]]; then
    error "Found an incomplete theme marker in $RENDERER_FILENAME. Restore the original app.asar before applying a theme."
fi

BACKUP_STAGE=""

if [[ "$HAS_BEGIN" -eq 1 ]]; then
    printf 'Theme markers already exist in the renderer CSS.\n'
    [[ -f "$BACKUP_ASAR" ]] || error \
        "The theme appears installed, but the original backup is missing: $BACKUP_ASAR"
    printf 'Keeping existing backup: %s\n' "$BACKUP_ASAR"
else
    printf 'Preparing a backup of the original app.asar...\n'

    BACKUP_STAGE="$(mktemp -d /opt/.FreeTube.backup.new.XXXXXX)"
    mkdir -p "$BACKUP_STAGE/resources"

    install -o root -g root -m 0644 \
        "$APP_ASAR" \
        "$BACKUP_STAGE/resources/app.asar"
fi

THEME_EXPANDED="$WORK/theme-expanded.css"

printf 'Combining CSS files and embedding images as Base64...\n'

python3 - "$THEME_IMG_DIR" "$THEME_EXPANDED" "${THEME_FILES[@]}" <<'PY'
import base64
import mimetypes
import pathlib
import re
import sys

image_dir = pathlib.Path(sys.argv[1])
output_file = pathlib.Path(sys.argv[2])
theme_files = [pathlib.Path(path) for path in sys.argv[3:]]

css_parts = []

for theme_file in theme_files:
    css_parts.append(
        "\n/* Source CSS: "
        + theme_file.name
        + " */\n\n"
        + theme_file.read_text(encoding="utf-8")
        + "\n"
    )

css = "\n".join(css_parts)

image_data = {}

for image_path in image_dir.iterdir():
    if image_path.is_symlink() or not image_path.is_file():
        continue

    if image_path.suffix.lower() not in {".png", ".jpg", ".jpeg"}:
        continue

    mime_type = mimetypes.guess_type(image_path.name)[0]
    if mime_type is None:
        continue

    image_data[image_path.name.lower()] = (
        "data:"
        + mime_type
        + ";base64,"
        + base64.b64encode(image_path.read_bytes()).decode("ascii")
    )

pattern = re.compile(
    r"(?P<prefix>(?:\./)?imgs/)(?P<name>[^)\s\"']+)",
    re.IGNORECASE,
)

embedded = 0

def replace_image(match):
    global embedded

    image_name = match.group("name").lower()
    replacement = image_data.get(image_name)

    if replacement is None:
        return match.group(0)

    embedded += 1
    return replacement

css = pattern.sub(replace_image, css)
output_file.write_text(css, encoding="utf-8")

print(f"Embedded {embedded} image reference(s) as Base64.")
PY

THEMED_CSS="$WORK/$RENDERER_FILENAME"

{
    printf '%s\n' "$THEME_BEGIN"
    cat "$THEME_EXPANDED"
    printf '\n%s\n' "$THEME_END"
} > "$THEMED_CSS"

printf 'Installing themed renderer CSS in the extracted app...\n'
install -o root -g root -m 0644 "$THEMED_CSS" "$RENDERER_CSS"

DIST_IMG_DIR="$DIST_DIR/imgs"
printf 'Copying theme images...\n'
rm -rf -- "$DIST_IMG_DIR"
mkdir -p "$DIST_IMG_DIR"
cp -a "$THEME_IMG_DIR"/. "$DIST_IMG_DIR"/

printf 'Repacking app.asar...\n'
"$ASAR_BIN" pack \
    "$WORK/freetube-app" \
    "$WORK/app-themed.asar" \
    --unpack '*.node'

[[ -f "$WORK/app-themed.asar" ]] || error \
    "The modified app.asar was not created."

# Prepare the replacement beside app.asar so the final rename is atomic.
APP_STAGE="$(mktemp "$FREETUBE_DIR/resources/.app.asar.theme.XXXXXX")"
install -o root -g root -m 0644 "$WORK/app-themed.asar" "$APP_STAGE"

if [[ -n "$BACKUP_STAGE" ]]; then
    printf 'Installing original app.asar backup...\n'

    if [[ -e "$BACKUP_DIR" ]]; then
        BACKUP_OLD="/opt/.FreeTube.backup.old.$$.$RANDOM"
        while [[ -e "$BACKUP_OLD" ]]; do
            BACKUP_OLD="/opt/.FreeTube.backup.old.$$.$RANDOM"
        done
        mv -- "$BACKUP_DIR" "$BACKUP_OLD"
    fi

    mv -- "$BACKUP_STAGE" "$BACKUP_DIR"
    BACKUP_STAGE=""
fi

printf 'Installing themed app.asar...\n'
mv -f -- "$APP_STAGE" "$APP_ASAR"
APP_STAGE=""

# The new app.asar is installed successfully; the superseded backup can go.
if [[ -n "$BACKUP_OLD" && -e "$BACKUP_OLD" ]]; then
    if rm -rf -- "$BACKUP_OLD"; then
        BACKUP_OLD=""
    else
        printf 'WARNING: Could not remove the previous backup at:\n  %s\n' \
            "$BACKUP_OLD" >&2
    fi
fi

printf '\nFreeTube theme applied successfully.\n\n'
printf 'Original backup:\n  %s\n\n' "$BACKUP_ASAR"
printf 'Start FreeTube with:\n  freetube\n'

