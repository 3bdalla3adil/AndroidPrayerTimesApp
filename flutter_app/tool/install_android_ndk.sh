#!/usr/bin/env bash
set -Eeuo pipefail

# Keep this in sync with Flutter 3.47.5's default NDK revision.
# Installing it explicitly lets CI detect and recover from a corrupt SDK
# download before Gradle starts configuring the Android project.
readonly ndk_revision="28.2.13676358"
readonly sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:?ANDROID_HOME or ANDROID_SDK_ROOT must be set}}"
readonly ndk_path="${sdk_root}/ndk/${ndk_revision}"
readonly attempts=3

if [[ ! -x "${sdk_root}/cmdline-tools/latest/bin/sdkmanager" ]]; then
  echo "ERROR: sdkmanager was not found under ${sdk_root}" >&2
  exit 1
fi

if [[ -s "${ndk_path}/source.properties" ]] && grep -Fq "Pkg.Revision = ${ndk_revision}" "${ndk_path}/source.properties"; then
  echo "Android NDK ${ndk_revision} is already installed and valid."
  exit 0
fi

for attempt in $(seq 1 "${attempts}"); do
  echo "Installing Android NDK ${ndk_revision} (attempt ${attempt}/${attempts})"

  # sdkmanager can leave a corrupt archive and a partial NDK directory after
  # a failed transfer. Remove only this package's temporary/cache files.
  rm -rf "${ndk_path}"
  rm -rf "${sdk_root}/.downloadIntermediates" "${sdk_root}/.temp"

  if "${sdk_root}/cmdline-tools/latest/bin/sdkmanager" --install "ndk;${ndk_revision}" --sdk_root="${sdk_root}" &&
     [[ -s "${ndk_path}/source.properties" ]] &&
     grep -Fq "Pkg.Revision = ${ndk_revision}" "${ndk_path}/source.properties"; then
    echo "Android NDK ${ndk_revision} installed and validated."
    exit 0
  fi

  echo "NDK installation attempt ${attempt} failed." >&2
  rm -rf "${ndk_path}" "${sdk_root}/.downloadIntermediates" "${sdk_root}/.temp"
  if [[ "${attempt}" -lt "${attempts}" ]]; then
    sleep $((attempt * 10))
  fi
done

echo "ERROR: Could not install a valid Android NDK ${ndk_revision} after ${attempts} attempts." >&2
exit 1
