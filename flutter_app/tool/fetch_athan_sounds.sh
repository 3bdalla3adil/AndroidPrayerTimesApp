#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIO_DIR="$ROOT/assets/audio"
BASE="https://raw.githubusercontent.com/Kiwifu/adhan-mp3/main"

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

download "azan_madinah.mp3" "Adhan_Al_Haram_Al_Madani_-_Al_Madinah_2_(%D8%A3%D8%B0%D8%A7%D9%86_%D8%A7%D9%84%D8%AD%D8%B1%D9%85_%D8%A7%D9%84%D9%85%D8%AF%D9%86%D9%8A_-_%D8%A7%D9%84%D9%85%D8%AF%D9%8A%D9%86%D8%A9_%D8%A7%D9%84%D9%85%D9%86%D9%88%D8%B1%D8%A9).mp3"
download "azan_dubai.mp3" "Adhan_Dubai_UAE_(%D8%A3%D8%B0%D8%A7%D9%86_%D8%AF%D8%A8%D9%8A_%D8%A7%D9%84%D8%A5%D9%85%D8%A7%D8%B1%D8%A7%D8%AA).mp3"
download "azan_fajr_madinah.mp3" "Adhan_Fajr_Al_Haram_Al_Madani_(%D8%A3%D8%B0%D8%A7%D9%86_%D8%A7%D9%84%D9%81%D8%AC%D8%B1_%D8%A7%D9%84%D8%AD%D8%B1%D9%85_%D8%A7%D9%84%D9%85%D8%AF%D9%86%D9%8A).mp3"

for f in "$AUDIO_DIR"/azan_madinah.mp3 "$AUDIO_DIR"/azan_dubai.mp3 "$AUDIO_DIR"/azan_fajr_madinah.mp3; do
  size="$(wc -c < "$f" | tr -d ' ')"
  [[ "$size" -gt 10000 ]] || { echo "Invalid audio file: $f" >&2; exit 1; }
done

echo "Additional Athan sounds are ready."
