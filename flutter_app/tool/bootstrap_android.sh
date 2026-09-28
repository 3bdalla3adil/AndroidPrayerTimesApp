#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  flutter create --platforms=android --org=com.abdulla --project-name=salawat_quran .
fi

MANIFEST="android/app/src/main/AndroidManifest.xml"

python3 - "$MANIFEST" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

permissions = [
    '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
    '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
    '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
]

marker = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
for permission in permissions:
    if permission not in text:
        text = text.replace(marker, marker + '\n' + permission)

path.write_text(text)
PY

echo "Android platform is ready."
