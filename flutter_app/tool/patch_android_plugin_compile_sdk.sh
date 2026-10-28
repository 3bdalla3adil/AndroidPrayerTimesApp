#!/usr/bin/env bash
set -euo pipefail

# The app uses Android SDK 36. Some older Flutter plugins still declare a
# lower compile SDK, which causes CheckAarMetadata failures with newer AndroidX
# dependencies. Patch only the resolved geocoding_android package in Pub's
# cache; never install a global Gradle hook or modify unrelated plugins.

PUB_CACHE_DIR="${PUB_CACHE:-$HOME/.pub-cache}"
mapfile -t candidates < <(
  find "$PUB_CACHE_DIR/hosted" -type f \
    -path '*/geocoding_android-*/android/build.gradle' \
    ! -path '*/example/*' \
    -print 2>/dev/null | sort
)

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "ERROR: geocoding_android Android Gradle module not found in $PUB_CACHE_DIR/hosted" >&2
  exit 1
fi

for file in "${candidates[@]}"; do
  # Accept Groovy and Kotlin-style assignment syntax and values supplied via
  # Flutter's extension (for example: compileSdk = flutter.compileSdkVersion).
  # Replace the value, not the declaration syntax, so Gradle can still parse it.
  if grep -Eq '^[[:space:]]*compileSdk(Version)?([[:space:]]*=|[[:space:]]+)' "$file"; then
    sed -i -E \
      -e '/^[[:space:]]*compileSdkVersion[[:space:]]+/s/^([[:space:]]*compileSdkVersion[[:space:]]+).*/\1 36/' \
      -e '/^[[:space:]]*compileSdkVersion[[:space:]]*=/s/^([[:space:]]*compileSdkVersion[[:space:]]*=[[:space:]]*).*/\1 36/' \
      -e '/^[[:space:]]*compileSdk[[:space:]]*=/s/^([[:space:]]*compileSdk[[:space:]]*=[[:space:]]*).*/\1 36/' \
      -e '/^[[:space:]]*compileSdk[[:space:]]+/s/^([[:space:]]*compileSdk[[:space:]]+).*/\1 36/' \
      "$file"
  else
    # Do not silently continue when upstream changes its Gradle syntax. Inject
    # an explicit declaration into the Android block only when none exists.
    if ! grep -Eq '^[[:space:]]*android[[:space:]]*\{' "$file"; then
      echo "ERROR: Could not locate an Android Gradle block in $file" >&2
      exit 1
    fi
    sed -i -E '/^[[:space:]]*android[[:space:]]*\{/a\
    compileSdkVersion 36
    ' "$file"
  fi

  if ! grep -Eq '^[[:space:]]*compileSdk(Version)?([[:space:]]*=|[[:space:]]+)[[:space:]]*36([[:space:]]|$)' "$file"; then
    echo "ERROR: Failed to set compile SDK 36 in $file" >&2
    exit 1
  fi
  echo "Configured geocoding_android compile SDK 36: $file"
done
