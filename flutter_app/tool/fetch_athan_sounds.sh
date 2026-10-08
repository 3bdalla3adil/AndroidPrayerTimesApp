#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIO_DIR="$ROOT/assets/audio"
ANDROID_RAW_DIR="$ROOT/../app/src/main/res/raw"
ANDROID_ATHAN_SOURCE="$ANDROID_RAW_DIR/azan.mp3"

mkdir -p "$AUDIO_DIR"

download() {
  local name="$1"
  local out="$AUDIO_DIR/$name"

  if [[ -s "$out" ]]; then
    echo "Athan audio already present: $out"
    return
  fi

  if [[ -s "$ANDROID_ATHAN_SOURCE" ]]; then
    echo "Using bundled Android Athan asset: $ANDROID_ATHAN_SOURCE"
    cp "$ANDROID_ATHAN_SOURCE" "$out"
    test -s "$out"
    return
  fi

  echo "Missing bundled Android Athan asset: $ANDROID_ATHAN_SOURCE" >&2
  exit 1
}

# Prefer the repo's existing Android raw asset as the canonical Athan clip so the
# Flutter app and Android app stay in sync.
download "azan.mp3"
download "azan_madinah.mp3"
download "azan_dubai.mp3"
download "azan_fajr_madinah.mp3"

for f in "$AUDIO_DIR/azan.mp3" "$AUDIO_DIR/azan_madinah.mp3" "$AUDIO_DIR/azan_dubai.mp3" "$AUDIO_DIR/azan_fajr_madinah.mp3"; do
  size="$(wc -c < "$f" | tr -d ' ')"
  [[ "$size" -gt 10000 ]] || {
    echo "Invalid audio file: $f" >&2
    exit 1
  }
done

echo "Athan sounds are ready."
