#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/assets/quran"
PAGES="$OUT/pages"
INDEX="$OUT/page-index.json"
CACHE="$ROOT/.cache"
ZIP="$CACHE/madinah-mushaf-json.zip"
EXTRACT="$CACHE/madinah-mushaf-json"
SOURCE_REPO="ouryhamdalaye/madinah-mushaf-json"
SOURCE_URL="https://github.com/$SOURCE_REPO/archive/refs/heads/main.zip"

mkdir -p "$PAGES" "$CACHE"

echo "==> Generating Madinah Mushaf"
echo "    Source: $SOURCE_REPO"
echo "    Target: $PAGES"

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "ERROR: unzip is required." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required." >&2; exit 1; }

if [ ! -s "$ZIP" ]; then
  echo "==> Downloading Madinah Mushaf dataset..."
  curl -L --fail --retry 5 --retry-delay 2     -A "AndroidPrayerTimesApp-FlutterQuranBuilder/1.0"     -o "$ZIP" "$SOURCE_URL"
fi

rm -rf "$EXTRACT"
mkdir -p "$EXTRACT"
unzip -q -o "$ZIP" -d "$EXTRACT"

SOURCE="$(find "$EXTRACT" -type d -path '*/pages' | head -n 1)"
if [ -z "$SOURCE" ]; then
  echo "ERROR: Could not find dataset pages directory." >&2
  exit 1
fi

rm -rf "$PAGES"
mkdir -p "$PAGES"
cp "$SOURCE"/page-*.json "$PAGES"/

COUNT="$(find "$PAGES" -maxdepth 1 -type f -name 'page-*.json' | wc -l | tr -d ' ')"
if [ "$COUNT" -ne 604 ]; then
  echo "ERROR: Expected exactly 604 Mushaf pages, found $COUNT." >&2
  exit 1
fi

python3 - "$PAGES" "$INDEX" <<'PY'
import json
import pathlib
import sys

pages = pathlib.Path(sys.argv[1])
index_path = pathlib.Path(sys.argv[2])
starts = {}

for path in sorted(pages.glob("page-*.json")):
    page = int(path.stem.split("-")[-1])
    data = json.loads(path.read_text(encoding="utf-8"))
    for verse in data.get("verses", []):
        surah = int(verse.get("surah_number", 0))
        if surah and str(surah) not in starts:
            starts[str(surah)] = page

if len(starts) != 114:
    raise SystemExit(f"Expected 114 surah starts, found {len(starts)}")

index_path.write_text(
    json.dumps(
        {
            "mushaf": "Madinah Mushaf",
            "edition": "Hafs an Asim",
            "totalPages": 604,
            "surahStartPages": starts,
        },
        ensure_ascii=False,
        indent=2,
    ),
    encoding="utf-8",
)

print("Generated 604 Madinah Mushaf pages and 114 surah start mappings.")
PY

echo "==> Madinah Mushaf generation completed successfully."
