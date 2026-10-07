#!/usr/bin/env bash
set -e

# 1. Generate the android project
flutter create --platforms=android .

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

# 2b. Install the bundled Athan recording as an Android notification sound.
mkdir -p android/app/src/main/res/raw
cp -f assets/audio/azan.mp3 android/app/src/main/res/raw/azan.mp3

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
    "android.permission.USE_BIOMETRIC",
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
p.write_text(s)
PY

# local_auth on Android requires an AppCompat launch theme.
if [ -f android/app/src/main/res/values/styles.xml ]; then
  python3 - <<'PY'
from pathlib import Path
p = Path("android/app/src/main/res/values/styles.xml")
s = p.read_text()
s = s.replace('parent="Theme.MaterialComponents.DayNight.NoActionBar"',
              'parent="Theme.AppCompat.DayNight.NoActionBar"')
s = s.replace('parent="Theme.Material.Light.NoActionBar"',
              'parent="Theme.AppCompat.Light.NoActionBar"')
p.write_text(s)
PY
fi

# 3b. local_auth requires FragmentActivity for Android biometric prompts.
python3 - <<'PY'
from pathlib import Path
candidates = [
    Path("android/app/src/main/kotlin/com/salawat_quran/MainActivity.kt"),
    Path("android/app/src/main/kotlin/com/salawat_quran/salawat_quran/MainActivity.kt"),
]
for p in candidates:
    if p.exists():
        text = p.read_text()
        text = text.replace("import io.flutter.embedding.android.FlutterActivity",
                            "import io.flutter.embedding.android.FlutterFragmentActivity")
        text = text.replace("extends FlutterActivity", "extends FlutterFragmentActivity")
        text = text.replace(": FlutterActivity()", ": FlutterFragmentActivity()")
        p.write_text(text)
        print(f"Patched {p} for local_auth.")
        break
else:
    raise SystemExit("ERROR: generated MainActivity.kt not found")
PY

# 4. Sanity check
grep -n "coreLibraryDesugaringEnabled\|coreLibraryDesugaring" android/app/build.gradle* || {
  echo "ERROR: desugaring patch failed"
  exit 1
}

echo "Bootstrap complete."
