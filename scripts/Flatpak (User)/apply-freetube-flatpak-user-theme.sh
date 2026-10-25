#!/usr/bin/env bash
set -Eeuo pipefail

APP_ID="io.freetubeapp.FreeTube"
ARCH="x86_64"
BRANCH="stable"

ACTIVE_CANDIDATE="$HOME/.local/share/flatpak/app/$APP_ID/$ARCH/$BRANCH/active/files/freetube/resources/app.asar"

THEME_DIR="$HOME/.scripts/Freetube Themes/000 Active"
THEME_IMG_DIR="$THEME_DIR/imgs"

BACKUP_DIR="$HOME/.local/share/FreeTube.backup"
BACKUP_RESOURCES="$BACKUP_DIR/resources"
BACKUP_ASAR="$BACKUP_RESOURCES/app.asar"

THEME_BEGIN="/* FREETUBE-RICING-LAB-THEME-BEGIN */"
THEME_END="/* FREETUBE-RICING-LAB-THEME-END */"

WORK="$(mktemp -d)"
BACKUP_STAGE_ASAR=""
APP_ASAR_TMP=""

cleanup() {
    rm -rf -- "$WORK"

    if [[ -n "$BACKUP_STAGE_ASAR" && -e "$BACKUP_STAGE_ASAR" ]]; then
        rm -f -- "$BACKUP_STAGE_ASAR"
    fi

    if [[ -n "$APP_ASAR_TMP" && -e "$APP_ASAR_TMP" ]]; then
        rm -f -- "$APP_ASAR_TMP"
    fi
}
trap cleanup EXIT

error() {
    echo "ERROR: $*" >&2
    exit 1
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

[[ -d "$THEME_DIR" && ! -L "$THEME_DIR" ]] || error \
    "Theme directory is missing or is a symlink:
$THEME_DIR"

[[ -d "$THEME_IMG_DIR" && ! -L "$THEME_IMG_DIR" ]] || error \
    "Theme image directory is missing or is a symlink:
$THEME_IMG_DIR"

if find "$THEME_DIR" -maxdepth 1 -type l -name '*.css' -print -quit | grep -q .; then
    error "The theme directory contains a symlinked CSS file."
fi

if find "$THEME_IMG_DIR" -type l -print -quit | grep -q .; then
    error "The theme image directory contains a symlink."
fi

mapfile -d '' THEME_FILES < <(
    find "$THEME_DIR" \
        -maxdepth 1 \
        -type f \
        -name '*.css' \
        -print0
)

[[ "${#THEME_FILES[@]}" -eq 1 ]] || error \
    "Expected exactly one CSS file inside:
$THEME_DIR

Found: ${#THEME_FILES[@]}"

THEME_FILE="${THEME_FILES[0]}"
THEME_SIZE="$(wc -c < "$THEME_FILE")"

[[ "$THEME_SIZE" -ge 100 ]] || error \
    "Theme CSS file is suspiciously small:
$THEME_FILE"

if grep -Fq "$THEME_BEGIN" "$THEME_FILE" ||
   grep -Fq "$THEME_END" "$THEME_FILE"; then
    error "The theme CSS contains reserved theme marker text."
fi

command -v python3 >/dev/null 2>&1 || error \
    "python3 is required but was not found."

command -v flatpak >/dev/null 2>&1 || error \
    "flatpak was not found."

ASAR_BIN="$(find_asar_command || true)"
[[ -n "$ASAR_BIN" ]] || error "Could not find the asar command."

[[ -f "$ACTIVE_CANDIDATE" && ! -L "$ACTIVE_CANDIDATE" ]] || error \
    "Could not find a regular app.asar in the active user-installed Flatpak deployment:
$ACTIVE_CANDIDATE

This script expects a user-installed Flatpak."

APP_ASAR="$(readlink -f -- "$ACTIVE_CANDIDATE")" || error \
    "Could not resolve the active Flatpak app.asar path."

[[ -f "$APP_ASAR" && ! -L "$APP_ASAR" ]] || error \
    "The active Flatpak app.asar is missing or is a symlink:
$APP_ASAR"

[[ -r "$APP_ASAR" && -w "$APP_ASAR" ]] || error \
    "The active Flatpak app.asar is not readable and writable:
$APP_ASAR

This script expects a user-installed Flatpak."

# Check backup paths before using them. A symlink here could redirect
# backup writes somewhere unintended.
[[ ! -L "$BACKUP_DIR" ]] || error \
    "The backup directory is a symlink:
$BACKUP_DIR"

[[ ! -L "$BACKUP_RESOURCES" ]] || error \
    "The backup resources directory is a symlink:
$BACKUP_RESOURCES"

if [[ -e "$BACKUP_ASAR" || -L "$BACKUP_ASAR" ]]; then
    [[ -f "$BACKUP_ASAR" && ! -L "$BACKUP_ASAR" ]] || error \
        "The backup path exists but is not a regular, non-symlink file:
$BACKUP_ASAR"
fi

echo "Using theme directory:"
echo "  $THEME_DIR"
echo "Using theme CSS:"
echo "  $THEME_FILE"
echo "Using theme images:"
echo "  $THEME_IMG_DIR"
echo "Using FreeTube app.asar:"
echo "  $APP_ASAR"
echo "Using asar:"
echo "  $ASAR_BIN"

echo
echo "Extracting app.asar..."

"$ASAR_BIN" extract "$APP_ASAR" "$WORK/freetube-app"

DIST_DIR="$WORK/freetube-app/dist"
[[ -d "$DIST_DIR" && ! -L "$DIST_DIR" ]] || error \
    "Could not find a regular dist directory inside app.asar:
$DIST_DIR"

RENDERER_FILENAME=""

while IFS= read -r -d '' file; do
    filename="$(basename "$file")"

    if [[ "$filename" =~ ^renderer\.[[:alnum:]]+\.css$ ]]; then
        [[ -z "$RENDERER_FILENAME" ]] || error \
            "More than one renderer.<hash>.css file was found inside:
$DIST_DIR"

        RENDERER_FILENAME="$filename"
    fi
done < <(
    find "$DIST_DIR" \
        -maxdepth 1 \
        -type f \
        -print0
)

[[ -n "$RENDERER_FILENAME" ]] || error \
    "Could not find renderer.<hash>.css inside:
$DIST_DIR"

RENDERER_CSS="$DIST_DIR/$RENDERER_FILENAME"
[[ ! -L "$RENDERER_CSS" ]] || error \
    "The renderer CSS file inside the extracted archive is a symlink."

echo "Found renderer CSS:"
echo "  $RENDERER_FILENAME"

MARKER_STATE="$(
    python3 - "$RENDERER_CSS" "$THEME_BEGIN" "$THEME_END" <<'PY'
import pathlib
import sys

css_path = pathlib.Path(sys.argv[1])
begin = sys.argv[2]
end = sys.argv[3]
text = css_path.read_text(encoding="utf-8")

begin_count = text.count(begin)
end_count = text.count(end)

if begin_count == 0 and end_count == 0:
    print("clean")
elif begin_count == 1 and end_count == 1 and text.index(begin) < text.index(end):
    print("themed")
else:
    raise SystemExit("Theme markers are incomplete, duplicated, or out of order.")
PY
)" || error \
    "The renderer CSS has invalid theme markers."

if [[ "$MARKER_STATE" == "themed" ]]; then
    echo "FreeTube already contains the theme markers."

    [[ -f "$BACKUP_ASAR" && ! -L "$BACKUP_ASAR" ]] || error \
        "The archive is themed, but the original backup is missing or is a symlink:
$BACKUP_ASAR"

    echo "Keeping the existing original backup:"
    echo "  $BACKUP_ASAR"
fi

echo "Embedding local background images into the theme CSS..."

THEME_EXPANDED="$WORK/theme-expanded.css"

python3 - "$THEME_FILE" "$THEME_IMG_DIR" "$THEME_EXPANDED" <<'PY'
import base64
import mimetypes
import pathlib
import sys

theme_file = pathlib.Path(sys.argv[1])
image_dir = pathlib.Path(sys.argv[2])
output_file = pathlib.Path(sys.argv[3])

css = theme_file.read_text(encoding="utf-8")

for filename in ("a.png", "a.jpg", "a.jpeg"):
    image_path = image_dir / filename

    if not image_path.is_file():
        print(f"Notice: {filename} was not found; leaving its URL unchanged.")
        continue

    mime_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
    encoded = base64.b64encode(image_path.read_bytes()).decode("ascii")
    data_uri = f"data:{mime_type};base64,{encoded}"

    css = css.replace(f"./imgs/{filename}", data_uri)

output_file.write_text(css, encoding="utf-8")
PY

echo "Applying theme CSS..."

THEMED_CSS="$WORK/$RENDERER_FILENAME"

{
    printf '%s\n' "$THEME_BEGIN"
    cat "$THEME_EXPANDED"
    printf '\n%s\n' "$THEME_END"
} > "$THEMED_CSS"

install -m 0644 "$THEMED_CSS" "$RENDERER_CSS"

DIST_IMG_DIR="$DIST_DIR/imgs"
if [[ -L "$DIST_IMG_DIR" ]]; then
    error "The extracted app contains a symlink at:
$DIST_IMG_DIR"
fi

echo "Installing theme images..."
rm -rf -- "$DIST_IMG_DIR"
mkdir -p "$DIST_IMG_DIR"
cp -a "$THEME_IMG_DIR"/. "$DIST_IMG_DIR"/

echo "Repacking app.asar..."

PACKED_ASAR="$WORK/app-themed.asar"

"$ASAR_BIN" pack \
    "$WORK/freetube-app" \
    "$PACKED_ASAR" \
    --unpack '*.node'

[[ -s "$PACKED_ASAR" ]] || error \
    "The modified app.asar was not created."

# Prepare the themed archive beside the target so the final rename is atomic.
APP_ASAR_TMP="$(mktemp "${APP_ASAR}.theme.XXXXXX")"
install -m 0644 "$PACKED_ASAR" "$APP_ASAR_TMP"

# On a clean archive, rotate the single backup to match this deployment.
# The staged backup replaces the previous backup atomically.
if [[ "$MARKER_STATE" == "clean" ]]; then
    echo "Staging the current original app.asar as the single rolling backup..."

    mkdir -p "$BACKUP_RESOURCES"

    [[ ! -L "$BACKUP_DIR" && ! -L "$BACKUP_RESOURCES" ]] || error \
        "A backup directory became a symlink; refusing to write a backup."

    BACKUP_STAGE_ASAR="$(mktemp "$BACKUP_RESOURCES/.app.asar.new.XXXXXX")"
    install -m 0644 "$APP_ASAR" "$BACKUP_STAGE_ASAR"

    [[ -f "$APP_ASAR" && ! -L "$APP_ASAR" ]] || error \
        "The target app.asar changed or became a symlink before installation:
$APP_ASAR"

    mv -fT -- "$BACKUP_STAGE_ASAR" "$BACKUP_ASAR"
    BACKUP_STAGE_ASAR=""
fi

# Make sure Flatpak did not switch deployments while the script was working.
CURRENT_ACTIVE_ASAR="$(readlink -f -- "$ACTIVE_CANDIDATE" 2>/dev/null || true)"
[[ "$CURRENT_ACTIVE_ASAR" == "$APP_ASAR" ]] || error \
    "The active Flatpak deployment changed while the script was running. No themed archive was installed."

[[ -f "$APP_ASAR" && ! -L "$APP_ASAR" ]] || error \
    "The target app.asar changed or became a symlink before installation:
$APP_ASAR"

echo
echo "Stopping FreeTube..."
flatpak kill "$APP_ID" 2>/dev/null || true
sleep 2

echo "Installing themed app.asar atomically..."
mv -fT -- "$APP_ASAR_TMP" "$APP_ASAR"
APP_ASAR_TMP=""

[[ -f "$APP_ASAR" && ! -L "$APP_ASAR" ]] || error \
    "The themed app.asar was not installed correctly."

echo
echo "FreeTube Flatpak theme applied successfully."
echo
echo "Single rolling original backup:"
echo "  $BACKUP_ASAR"
echo
echo "Start FreeTube with:"
echo "  flatpak run $APP_ID"

