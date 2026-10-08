#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIO_DIR="$ROOT/assets/audio"
ANDROID_RAW_DIR="$ROOT/../app/src/main/res/raw"
ANDROID_ATHAN_SOURCE="$ANDROID_RAW_DIR/azan.mp3"
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

  if [[ -s "$ANDROID_ATHAN_SOURCE" ]]; then
    echo "Using bundled Android Athan asset: $ANDROID_ATHAN_SOURCE"
    cp "$ANDROID_ATHAN_SOURCE" "$out"
    test -s "$out"
    return
  fi

  echo "Downloading $name from $url..."
  curl --fail --location --retry 3 --retry-delay 2 --connect-timeout 20 --max-time 120 "$url" -o "$out"
  test -s "$out"
}

# Prefer the repo's existing Android raw asset as the canonical Athan clip so the
# Flutter app and Android app stay in sync. Fall back to the upstream source only
# if the Android bundle is not available in this checkout.
#
# The upstream repository publishes its recordings as azan_1.mp3 ... azan_11.mp3.
# We keep the same naming for each UI option, but point all copies at the bundled
# Android asset so CI/build preparation does not fail on missing or invalid nested
# paths.
download "azan.mp3" "azan_1.mp3"
download "azan_madinah.mp3" "azan_1.mp3"
download "azan_dubai.mp3" "azan_1.mp3"
download "azan_fajr_madinah.mp3" "azan_1.mp3"

for f in "$AUDIO_DIR/azan.mp3" "$AUDIO_DIR/azan_madinah.mp3" "$AUDIO_DIR/azan_dubai.mp3" "$AUDIO_DIR/azan_fajr_madinah.mp3"; do
  size="$(wc -c < "$f" | tr -d ' ')"
  [[ "$size" -gt 10000 ]] || {
    echo "Invalid audio file: $f" >&2
    exit 1
  }
done

echo "Athan sounds are ready."
