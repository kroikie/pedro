#!/usr/bin/env bash
set -euo pipefail

# Configuration
FIREBASE_IOS_APP_ID="1:260654198138:ios:605e1e7955b0fb52527ac3"
DEFAULT_GROUPS="player-players"
GROUPS="${1:-$DEFAULT_GROUPS}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
APP_DIR="${ROOT_DIR}/app"
RELEASE_NOTES_FILE="${SCRIPT_DIR}/release_notes.txt"

echo "========================================="
echo " Building Pedro iOS Beta (Ad-Hoc)        "
echo "========================================="
cd "${APP_DIR}"
flutter pub get
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

IPA_PATH=$(find "${APP_DIR}/build/ios/ipa" -name "*.ipa" | head -n 1)

if [[ ! -f "${IPA_PATH}" ]]; then
  echo "Error: No IPA file found in ${APP_DIR}/build/ios/ipa"
  exit 1
fi

echo "========================================="
echo " Distributing to Firebase App Distribution"
echo " Target Groups: ${GROUPS}                "
echo " IPA: ${IPA_PATH}                        "
echo "========================================="

if [[ -f "${RELEASE_NOTES_FILE}" ]]; then
  firebase appdistribution:distribute "${IPA_PATH}" \
    --app "${FIREBASE_IOS_APP_ID}" \
    --groups "${GROUPS}" \
    --release-notes-file "${RELEASE_NOTES_FILE}"
else
  firebase appdistribution:distribute "${IPA_PATH}" \
    --app "${FIREBASE_IOS_APP_ID}" \
    --groups "${GROUPS}" \
    --release-notes "New iOS beta build for Pedro"
fi

echo "✅ iOS Beta distributed successfully!"
