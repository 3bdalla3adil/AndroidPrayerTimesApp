#!/usr/bin/env bash
set -euo pipefail

PLIST="ios/Runner/Info.plist"
if [[ ! -f "$PLIST" ]]; then
  echo "ERROR: $PLIST was not generated. Run flutter create --platforms=ios first."
  exit 1
fi

python3 - <<'PY'
import plistlib
from pathlib import Path

path = Path("ios/Runner/Info.plist")
with path.open("rb") as source:
    data = plistlib.load(source)

data["NSLocationWhenInUseUsageDescription"] = (
    "Your location is used while you use the app to calculate local prayer "
    "times and Qibla direction and to identify your city and country."
)
# The app does not track location in the background, so intentionally do not
# request Always authorization or add background-location capabilities.
with path.open("wb") as destination:
    plistlib.dump(data, destination, fmt=plistlib.FMT_XML, sort_keys=False)

with path.open("rb") as source:
    verified = plistlib.load(source)
assert verified.get("NSLocationWhenInUseUsageDescription")
assert "NSLocationAlwaysUsageDescription" not in verified
print("Configured foreground-only iOS location permission usage description.")
PY
