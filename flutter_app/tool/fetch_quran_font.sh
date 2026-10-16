#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FONT_DIR="$ROOT/assets/fonts"
FONT="$FONT_DIR/KFGQPC-Hafs-Uthmanic-Script.ttf"
URL="https://cdn.jsdelivr.net/gh/thetruetruth/quran-data-kfgqpc@main/hafs/font/hafs.18.ttf"

mkdir -p "$FONT_DIR"

if [[ -s "$FONT" ]]; then
  SIZE="$(wc -c < "$FONT" | tr -d ' ')"
  if [[ "$SIZE" -ge 200000 ]]; then
    echo "KFGQPC Hafs font already present: $FONT ($SIZE bytes)"
    exit 0
  fi
fi

echo "Downloading KFGQPC Hafs Uthmanic Script v18..."
curl --fail --location --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 120 "$URL" -o "$FONT"

SIZE="$(wc -c < "$FONT" | tr -d ' ')"
if [[ "$SIZE" -lt 200000 ]]; then
  echo "Downloaded font is unexpectedly small: $SIZE bytes" >&2
  rm -f "$FONT"
  exit 1
fi

echo "KFGQPC Hafs font ready: $FONT ($SIZE bytes)"
