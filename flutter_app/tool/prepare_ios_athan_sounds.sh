#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIO_DIR="$ROOT/assets/audio"
IOS_DIR="$ROOT/ios/Runner"

command -v ffmpeg >/dev/null 2>&1 || {
  echo "ERROR: ffmpeg is required to prepare iOS notification sounds." >&2
  exit 1
}

mkdir -p "$IOS_DIR"

# iOS custom notification sounds must be shorter than 30 seconds. Generate
# 29-second linear-PCM WAV clips so the system can play the Athan at delivery.
for sound in azan azan_madinah azan_dubai azan_fajr_madinah; do
  input="$AUDIO_DIR/$sound.mp3"
  output="$IOS_DIR/$sound.wav"
  test -s "$input"
  ffmpeg -y -loglevel error     -i "$input"     -t 29     -ar 22050     -ac 1     -c:a pcm_s16le     "$output"
  test -s "$output"
done

echo "iOS Athan notification sounds prepared."
