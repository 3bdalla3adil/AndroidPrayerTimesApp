#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIO_DIR="$ROOT/assets/audio"
BASE="https://raw.githubusercontent.com/Golyriun/adhan-audio/main"

mkdir -p "$AUDIO_DIR"

download() {
  local name="$1"
  local url="$BASE/$2"
  local out="$AUDIO_DIR/$name"
  if [[ -s "$out" ]]; then
    echo "Athan audio already present: $out"
    return
  fi
  echo "Downloading $name..."
  curl --fail --location --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 120 "$url" -o "$out"
  test -s "$out"
}

# Use the new public audio source and keep the app's expected filenames.
# The upstream repository exposes multiple azan variants as azan_1.mp3, azan_2.mp3, etc.
download "azan.mp3" "azan_1.mp3"
download "azan_madinah.mp3" "azan_2.mp3"
download "azan_dubai.mp3" "azan_3.mp3"
download "azan_fajr_madinah.mp3" "azan_4.mp3"

for f in "$AUDIO_DIR"/azan.mp3 "$AUDIO_DIR"/azan_madinah.mp3 "$AUDIO_DIR"/azan_dubai.mp3 "$AUDIO_DIR"/azan_fajr_madinah.mp3; do
  size="$(wc -c < "$f" | tr -d ' ')"
  [[ "$size" -gt 10000 ]] || { echo "Invalid audio file: $f" >&2; exit 1; }
 done

echo "Additional Athan sounds are ready."
