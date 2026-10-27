#!/usr/bin/env bash
set -e

# 1. Generate the android project
flutter create --platforms=android .

# Keep the generated Android project compatible with current AndroidX AAR metadata.
# compileSdk only affects APIs available at build time; runtime target behavior is
# intentionally left unchanged.
python3 - <<'PY'
from pathlib import Path
import re

candidates = (Path("android/app/build.gradle"), Path("android/app/build.gradle.kts"))
for path in candidates:
    if not path.exists():
        continue
    source = path.read_text()
    if path.name.endswith(".kts"):
        if re.search(r"(?m)^\s*compileSdk\s*=", source):
            source = re.sub(r"(?m)^(\s*compileSdk\s*=).*?$", r"\g<1> 36", source, count=1)
        else:
            source = re.sub(r"(?m)^(\s*android\s*\{)", r"\1\n    compileSdk = 36", source, count=1)
    else:
        if re.search(r"(?m)^\s*compileSdkVersion\s+", source):
            source = re.sub(r"(?m)^(\s*compileSdkVersion\s+).*?$", r"\g<1>36", source, count=1)
        elif re.search(r"(?m)^\s*compileSdk\s+", source):
            source = re.sub(r"(?m)^(\s*compileSdk\s+).*?$", r"\g<1>36", source, count=1)
        else:
            source = re.sub(r"(?m)^(\s*android\s*\{)", r"\1\n    compileSdkVersion 36", source, count=1)
    path.write_text(source)
    if not re.search(r"(?m)^\s*(?:compileSdkVersion\s+36|compileSdk\s*(?:=\s*)36)\s*$", source):
        raise SystemExit(f"Failed to set compileSdk 36 in {path}")
    print(f"Configured compileSdk 36 in {path}")
    break
else:
    raise SystemExit("No generated Android app Gradle file found")
PY

# Some Flutter Android plugins (notably geocoding_android) declare their own
# compileSdk. Align Android subprojects with the app SDK so AAR metadata checks
# use the supported API level instead of each plugin's legacy default.
python3 - <<'PY'
from pathlib import Path

# Flutter 3.47 generates Kotlin DSL by default. Patch whichever root Gradle
# script was generated, rather than assuming the older Groovy filename.
groovy = Path("android/build.gradle")
kotlin = Path("android/build.gradle.kts")
if groovy.exists():
    source = groovy.read_text()
    if "compileSdkVersion 36" not in source:
        source += """\n\n// Align Android library plugins with the app's compile SDK.\nsubprojects { project ->\n    afterEvaluate {\n        if (project.hasProperty('android')) {\n            project.android { compileSdkVersion 36 }\n        }\n    }\n}\n"""
        groovy.write_text(source)
    print("Aligned Android plugin subprojects to compileSdk 36 (Groovy DSL)")
elif kotlin.exists():
    source = kotlin.read_text()
    marker = "// Align Android library plugins with the app's compile SDK."
    if marker not in source:
        source += """\n\n// Align Android library plugins with the app's compile SDK.\nsubprojects { subproject ->\n    subproject.afterEvaluate {\n        val androidExtension = subproject.extensions.findByName("android")\n        if (androidExtension != null) {\n            val compileSdkSetter = androidExtension.javaClass.methods.firstOrNull {\n                it.name == "setCompileSdk" && it.parameterCount == 1\n            }\n            compileSdkSetter?.invoke(androidExtension, 36)\n        }\n    }\n}\n"""
        kotlin.write_text(source)
    print("Aligned Android plugin subprojects to compileSdk 36 (Kotlin DSL)")
else:
    raise SystemExit("Generated Android root Gradle script not found")
PY

# 2. Enable core library desugaring required by flutter_local_notifications
GRADLE_FILE="android/app/build.gradle"
KTS_FILE="android/app/build.gradle.kts"

if [ -f "$GRADLE_FILE" ]; then
  # Groovy DSL (default for most Flutter versions)
  python3 - <<'PY'
import re
p = "android/app/build.gradle"
s = open(p).read()

# Enable desugaring inside compileOptions
s = re.sub(
    r"(compileOptions\s*\{[^}]*?)(\n\s*\})",
    r"\1\n        coreLibraryDesugaringEnabled true\2",
    s, count=1, flags=re.S)

# If no compileOptions block exists, add one
if "coreLibraryDesugaringEnabled" not in s:
    s = re.sub(
        r"(android\s*\{)",
        r"""\1
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
        coreLibraryDesugaringEnabled true
    }""",
        s, count=1)

# Add the desugaring dependency
if "coreLibraryDesugaring" not in s.split("dependencies")[-1]:
    if "dependencies {" in s:
        s = s.replace(
            "dependencies {",
            "dependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'",
            1)
    else:
        s += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"

# Enable multidex (also required by the notifications plugin)
if "multiDexEnabled" not in s:
    s = re.sub(
        r"(defaultConfig\s*\{)",
        r"\1\n        multiDexEnabled true",
        s, count=1)

open(p, "w").write(s)
print("Patched android/app/build.gradle")
PY
fi

if [ -f "$KTS_FILE" ]; then
  # Kotlin DSL (used by Flutter 3.29+)
  python3 - <<'PY'
import re
p = "android/app/build.gradle.kts"
s = open(p).read()

if "coreLibraryDesugaringEnabled" not in s:
    s = re.sub(
        r"(compileOptions\s*\{)",
        r"""\1
        isCoreLibraryDesugaringEnabled = true""",
        s, count=1)

if "coreLibraryDesugaring" not in s.split("dependencies")[-1]:
    if "dependencies {" in s:
        s = s.replace(
            "dependencies {",
            'dependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")',
            1)
    else:
        s += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'

if "multiDexEnabled" not in s:
    s = re.sub(
        r"(defaultConfig\s*\{)",
        r"\1\n        multiDexEnabled = true",
        s, count=1)

open(p, "w").write(s)
print("Patched android/app/build.gradle.kts")
PY
fi

python3 - <<'PY'
from pathlib import Path
for name in ("android/app/build.gradle", "android/app/build.gradle.kts"):
    p = Path(name)
    if not p.exists():
        continue
    s = p.read_text()
    s = s.replace("minSdkVersion flutter.minSdkVersion", "minSdkVersion 24")
    s = s.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
    p.write_text(s)
PY

# 2b. Install the bundled Athan recording as an Android notification sound.
bash tool/fetch_athan_sounds.sh
mkdir -p android/app/src/main/res/raw
cp -f assets/audio/azan.mp3 android/app/src/main/res/raw/azan.mp3
cp -f assets/audio/azan_madinah.mp3 android/app/src/main/res/raw/azan_madinah.mp3
cp -f assets/audio/azan_dubai.mp3 android/app/src/main/res/raw/azan_dubai.mp3
cp -f assets/audio/azan_fajr_madinah.mp3 android/app/src/main/res/raw/azan_fajr_madinah.mp3
cat > android/app/src/main/res/raw/keep.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@raw/azan,@raw/azan_madinah,@raw/azan_dubai,@raw/azan_fajr_madinah" />
XML

# 3. Add runtime permissions required by prayer, Qibla, notifications and exact scheduling.
MANIFEST="android/app/src/main/AndroidManifest.xml"
python3 - <<'PY'
from pathlib import Path
p = Path("android/app/src/main/AndroidManifest.xml")
s = p.read_text()
permissions = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
    "android.permission.WAKE_LOCK",
]
for permission in permissions:
    tag = f'    <uses-permission android:name="{permission}" />'
    if permission not in s:
        s = s.replace("<manifest ", "<manifest ", 1)
        pos = s.find(">") + 1
        s = s[:pos] + "\n" + tag + s[pos:]
p.write_text(s)

# ScheduledNotificationReceiver delivers the alarm, while the boot receiver
# restores pending alarms after Android restarts the device.
app = s.find("<application")
if app < 0:
    raise SystemExit("ERROR: AndroidManifest.xml has no application element")
app_end = s.find(">", app) + 1
receivers = """
    <receiver
        android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
    <receiver
        android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED" />
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            <action android:name="android.intent.action.QUICKBOOT_POWERON" />
            <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
        </intent-filter>
    </receiver>
"""
if "ScheduledNotificationReceiver" not in s:
    s = s[:app_end] + receivers + s[app_end:]

# Keep the Athan raw resource statically referenced so release resource
# processing cannot discard the dynamically selected notification sound.
if "com.salawat_quran.athan_sound_resource" not in s:
    app = s.find("<application")
    app_end = s.find(">", app) + 1
    metadata = '\n        <meta-data android:name="com.salawat_quran.athan_sound_resource" android:resource="@raw/azan" />\n'
    s = s[:app_end] + metadata + s[app_end:]
p.write_text(s)
PY

# Keep runtime notification resources intact in release builds.
python3 - <<'PY'
from pathlib import Path
import re

for name in ("android/app/build.gradle", "android/app/build.gradle.kts"):
    p = Path(name)
    if not p.exists():
        continue
    s = p.read_text()
    if name.endswith(".gradle"):
        pattern = r"(release\s*\{)"
        if "shrinkResources false" not in s:
            s = re.sub(
                pattern,
                r"\1\n        shrinkResources false",
                s,
                count=1,
            )
    else:
        pattern = r'(getByName\("release"\)\s*\{)'
        if "isShrinkResources = false" not in s:
            s = re.sub(
                pattern,
                r"\1\n        isShrinkResources = false",
                s,
                count=1,
            )
    p.write_text(s)
PY

# 4. Sanity check
grep -n "coreLibraryDesugaringEnabled\|coreLibraryDesugaring" android/app/build.gradle* || {
  echo "ERROR: desugaring patch failed"
  exit 1
}

echo "Bootstrap complete."
