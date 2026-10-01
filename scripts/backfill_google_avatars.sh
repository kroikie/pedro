#!/usr/bin/env bash
# scripts/backfill_google_avatars.sh
# Administrative script to backfill existing Google sign-in users with their Google profile photo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Running Google Avatar Backfill Script..."
cd "${REPO_ROOT}/functions"
dart run bin/backfill_google_avatars.dart "$@"
