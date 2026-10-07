for n in $(seq -w 1 604); do test -f "$PAGES/page-$n.json" || exit 1; done
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/assets/quran"
PAGES="$OUT/pages"\nINDEX="$OUT/page-index.json"
ZIP="$ROOT/.cache/madinah-mushaf-json.zip"
mkdir -p "$PAGES" "$(dirname "$ZIP")"

if [ ! -s "$ZIP" ]; then
  curl -L --fail --retry 4 --retry-delay 2 \
    -A "AndroidPrayerTimesApp-FlutterQuranBuilder/1.0" \
    -o "$ZIP" \
    "https://github.com/ouryhamdalaye/madinah-mushaf-json/archive/refs/heads/main.zip"
fi

rm -rf "$ROOT/.cache/madinah-mushaf-json"
mkdir -p "$ROOT/.cache/madinah-mushaf-json"
unzip -q -o "$ZIP" -d "$ROOT/.cache/madinah-mushaf-json"

SOURCE="$(find "$ROOT/.cache/madinah-mushaf-json" -type d -path '*/pages' | head -n 1)"
test -n "$SOURCE"

rm -rf "$PAGES"
mkdir -p "$PAGES"
cp "$SOURCE"/page-*.json "$PAGES"/


python3 - "$PAGES" "$OUT/page-index.json" <<'PY'
import json, pathlib, sys

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
    json.dumps({"totalPages": 604, "surahStartPages": starts}, ensure_ascii=False, indent=2),
    encoding="utf-8",
)
PY

echo "Generated $COUNT offline Madinah Mushaf pages."
