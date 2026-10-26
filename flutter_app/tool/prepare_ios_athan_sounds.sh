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

# Register the generated WAV files in the Runner target's Copy Bundle Resources phase.
# Flutter create does not automatically add files created after project generation.
python3 - <<'PY'
from pathlib import Path
import re

project = Path("ios/Runner.xcodeproj/project.pbxproj")
text = project.read_text()
sounds = ("azan.wav", "azan_madinah.wav", "azan_dubai.wav", "azan_fajr_madinah.wav")
resources = re.search(r"(PBXResourcesBuildPhase section \*/.*?)(\n\t\t\t\t\t\t\tfiles = \(.*?\n\t\t\t\t\t\t\t\);)", text, re.S)
if not resources:
    # Use the first PBXResourcesBuildPhase files list; this is the Runner app target.
    match = re.search(r"(\w+ /\* Resources \*/ = \{.*?files = \(.*?)(\n\t\t\t\t\t\t\t\);", text, re.S)
else:
    match = None

# Insert PBXBuildFile and PBXFileReference records only if absent.
build_records = []
file_records = []
for index, sound in enumerate(sounds):
    stem = sound.removesuffix(".wav")
    file_id = f"A7A0000000000000000000{index+1:02X}"
    build_id = f"A7B0000000000000000000{index+1:02X}"
    if f"\t\t{file_id} /* {sound} */" not in text:
        file_records.append(f"\t\t{file_id} /* {sound} */ = {{isa = PBXFileReference; lastKnownFileType = audio.wav; path = {sound}; sourceTree = \"<group>\"; }};")
    if f"\t\t{build_id} /* {sound} in Resources */" not in text:
        build_records.append(f"\t\t{build_id} /* {sound} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {sound} */; }};")
    if f"{build_id} /* {sound} in Resources */" not in text:
        # Add each sound to the Runner Resources phase (the first phase matching that name).
        phase = re.search(r"(\w+ /\* Resources \*/ = \{[^}]*?files = \()(.*?)(\);)", text, re.S)
        if not phase:
            raise SystemExit("Could not find Runner Copy Bundle Resources phase.")
        text = text[:phase.start(2)] + phase.group(2) + f"\n\t\t\t\t{build_id} /* {sound} in Resources */," + text[phase.end(2):]
    # Add reference to Runner group so it remains visible in Xcode.
    if f"{file_id} /* {sound} */" not in text:
        group = re.search(r"(\w+ /\* Runner \*/ = \{[^}]*?children = \()(.*?)(\);)", text, re.S)
        if not group:
            raise SystemExit("Could not find Runner group in project.pbxproj.")
        text = text[:group.start(2)] + group.group(2) + f"\n\t\t\t\t{file_id} /* {sound} */," + text[group.end(2):]

# Add records into their respective sections.
if build_records:
    marker = "/* End PBXBuildFile section */"
    text = text.replace(marker, "\n".join(build_records) + "\n" + marker, 1)
if file_records:
    marker = "/* End PBXFileReference section */"
    text = text.replace(marker, "\n".join(file_records) + "\n" + marker, 1)
project.write_text(text)
print("Registered all four iOS Athan WAV files in Runner resources.")
PY

echo "iOS Athan notification sounds prepared and bundled."
