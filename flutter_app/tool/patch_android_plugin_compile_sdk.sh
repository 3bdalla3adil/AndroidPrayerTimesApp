#!/usr/bin/env bash
set -euo pipefail

# Some transitive AndroidX AARs now require compileSdk >= 34. The app itself
# already compiles against SDK 36, but geocoding_android's library module can
# still declare SDK 33 and fail CheckAarMetadata before the app is compiled.
# Patch only the resolved package in Pub's cache; do not install a global
# Gradle hook, which can break unrelated plugins such as flutter_compass.

PUB_CACHE_DIR="${PUB_CACHE:-$HOME/.pub-cache}"
mapfile -t candidates < <(
  find "$PUB_CACHE_DIR/hosted" -type f \
    -path '*/geocoding_android-*/android/build.gradle' -print 2>/dev/null | sort
)

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "ERROR: geocoding_android Android Gradle module not found in $PUB_CACHE_DIR/hosted" >&2
  exit 1
fi

patched=0
for file in "${candidates[@]}"; do
  if grep -Eq 'compileSdkVersion[[:space:]]+33|compileSdk[[:space:]]*=[[:space:]]*33' "$file"; then
    sed -i -E \
      -e 's/compileSdkVersion[[:space:]]+33/compileSdkVersion 36/g' \
      -e 's/compileSdk[[:space:]]*=[[:space:]]*33/compileSdk = 36/g' \
      "$file"
    patched=1
    echo "Patched geocoding Android library compile SDK to 36: $file"
  elif grep -Eq 'compileSdkVersion[[:space:]]+([0-9]+)|compileSdk[[:space:]]*=[[:space:]]*([0-9]+)' "$file"; then
    # Do not downgrade a package that already targets a newer SDK.
    sdk="$(grep -Eo 'compileSdkVersion[[:space:]]+[0-9]+|compileSdk[[:space:]]*=[[:space:]]*[0-9]+' "$file" | head -n1 | grep -Eo '[0-9]+' | tail -n1)"
    if [ "$sdk" -lt 34 ]; then
      echo "ERROR: Unsupported geocoding_android compile SDK declaration in $file" >&2
      exit 1
    fi
    echo "geocoding_android already uses compile SDK $sdk: $file"
  else
    echo "ERROR: Could not identify compile SDK declaration in $file" >&2
    exit 1
  fi
done

if [ "$patched" -ne 1 ]; then
  echo "No patch was needed; all resolved geocoding_android modules already meet AndroidX metadata requirements."
fi
