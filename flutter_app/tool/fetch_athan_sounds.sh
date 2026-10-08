#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIO_DIR="$ROOT/assets/audio"
SOURCE_BASE="https://raw.githubusercontent.com/Golyriun/adhan-audio/main"

mkdir -p "$AUDIO_DIR"

download() {
  local name="$1"
  local source_file="$2"
  local url="$SOURCE_BASE/$source_file"
  local out="$AUDIO_DIR/$name"

  if [[ -s "$out" ]]; then
    echo "Athan audio already present: $out"
    return
  fi

  echo "Downloading $name from $url..."
  curl --fail --location --retry 3 --retry-delay 2     --connect-timeout 20 --max-time 120 "$url" -o "$out"
  test -s "$out"
}

# Golyriun/adhan-audio publishes its recordings as azan_1.mp3 ... azan_11.mp3.
# Use the verified azan_1.mp3 recording as the bundled baseline until the source
# repository exposes named recordings for the other UI choices. This keeps every
# Athan option playable and, importantly, removes the old invalid nested URL
# (azan_1.mp3/<filename>) that caused CI/build preparation to fail with HTTP 404.
download "azan.mp3" "azan_1.mp3"
download "azan_madinah.mp3" "azan_1.mp3"
download "azan_dubai.mp3" "azan_1.mp3"
download "azan_fajr_madinah.mp3" "azan_1.mp3"

for f in   "$AUDIO_DIR/azan.mp3"   "$AUDIO_DIR/azan_madinah.mp3"   "$AUDIO_DIR/azan_dubai.mp3"   "$AUDIO_DIR/azan_fajr_madinah.mp3"; do
  size="$(wc -c < "$f" | tr -d ' ')"
  [[ "$size" -gt 10000 ]] || {
    echo "Invalid audio file: $f" >&2
    exit 1
  }
done

echo "Athan sounds are ready."
