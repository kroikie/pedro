#!/usr/bin/env bash
set -euo pipefail

# Configuration
FIREBASE_ANDROID_APP_ID="1:260654198138:android:bd1ed81efcde0ad2527ac3"
DEFAULT_GROUPS="beta-testers"
GROUPS="${1:-$DEFAULT_GROUPS}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
APP_DIR="${ROOT_DIR}/app"
RELEASE_NOTES_FILE="${SCRIPT_DIR}/release_notes.txt"

echo "========================================="
echo " Building Pedro Android Release APK      "
echo "========================================="
cd "${APP_DIR}"
flutter pub get
flutter build apk --release

APK_PATH="${APP_DIR}/build/app/outputs/flutter-apk/app-release.apk"

if [[ ! -f "${APK_PATH}" ]]; then
  echo "Error: No APK file found at ${APK_PATH}"
  exit 1
fi

echo "========================================="
echo " Distributing to Firebase App Distribution"
echo " Target Groups: ${GROUPS}                "
echo " APK: ${APK_PATH}                        "
echo "========================================="

if [[ -f "${RELEASE_NOTES_FILE}" ]]; then
  firebase appdistribution:distribute "${APK_PATH}" \
    --app "${FIREBASE_ANDROID_APP_ID}" \
    --groups "${GROUPS}" \
    --release-notes-file "${RELEASE_NOTES_FILE}"
else
  firebase appdistribution:distribute "${APK_PATH}" \
    --app "${FIREBASE_ANDROID_APP_ID}" \
    --groups "${GROUPS}" \
    --release-notes "New Android beta build for Pedro"
fi

echo "✅ Android Beta distributed successfully!"
