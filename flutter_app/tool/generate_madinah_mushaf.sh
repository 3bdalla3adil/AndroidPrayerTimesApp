#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/assets/quran"
PAGES="$OUT/pages"
INDEX="$OUT/page-index.json"
CACHE="$ROOT/.cache/madinah-mushaf-json"
ZIP="$CACHE/madinah-mushaf-json.zip"

mkdir -p "$PAGES" "$CACHE"

echo "Downloading Madinah Mushaf dataset..."
if [ ! -s "$ZIP" ]; then
  curl -L --fail --retry 4 --retry-delay 2 \
    -A "AndroidPrayerTimesApp-FlutterQuranBuilder/1.0" \
    -o "$ZIP" \
    "https://github.com/ouryhamdalaye/madinah-mushaf-json/archive/refs/heads/main.zip"
fi

rm -rf "$CACHE/source"
mkdir -p "$CACHE/source"
unzip -q -o "$ZIP" -d "$CACHE/source"

SOURCE="$(find "$CACHE/source" -type d -name pages -print -quit)"
if [ -z "$SOURCE" ]; then
  echo "ERROR: Dataset archive does not contain a pages directory." >&2
  exit 1
fi

rm -rf "$PAGES"
mkdir -p "$PAGES"
cp "$SOURCE"/page-*.json "$PAGES"/

COUNT="$(find "$PAGES" -maxdepth 1 -type f -name 'page-*.json' | wc -l | tr -d ' ')"
if [ "$COUNT" -ne 604 ]; then
  echo "ERROR: Expected 604 Mushaf pages, found $COUNT." >&2
  exit 1
fi

for n in $(seq 1 604); do
  filename="$(printf 'page-%03d.json' "$n")"
  if [ ! -s "$PAGES/$filename" ]; then
    echo "ERROR: Missing Mushaf page: $filename" >&2
    exit 1
  fi
done

python3 - "$PAGES" "$INDEX" <<'PY'
import json
import pathlib
import sys

pages = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
starts = {}

for path in sorted(pages.glob("page-*.json")):
    data = json.loads(path.read_text(encoding="utf-8"))
    page = int(path.stem.split("-")[-1])
    for verse in data.get("verses", []):
        surah = int(verse.get("surah_number", 0))
        if surah and surah not in starts:
            starts[str(surah)] = page

if len(starts) != 114:
    raise SystemExit(f"Expected 114 surah starts, found {len(starts)}")

out.write_text(
    json.dumps(
        {"totalPages": 604, "surahStartPages": starts},
        ensure_ascii=False,
        indent=2,
    ),
    encoding="utf-8",
)

print(f"Generated {len(list(pages.glob('page-*.json')))} offline Madinah Mushaf pages.")
PY
