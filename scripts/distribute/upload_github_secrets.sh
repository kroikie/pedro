#!/usr/bin/env bash
set -euo pipefail

REPO="kroikie/pedro"

echo "=========================================================="
echo " Uploading iOS & Android Secrets to GitHub (${REPO})      "
echo "=========================================================="

if ! command -v gh &> /dev/null; then
  echo "Error: GitHub CLI (gh) is not installed. Install it with: brew install gh"
  exit 1
fi

if ! gh auth status &> /dev/null; then
  echo "Please authenticate with GitHub CLI first:"
  gh auth login
fi

echo ""
echo "--- iOS Signing Credentials ---"
read -rp "Upload iOS secrets? (y/n): " UPLOAD_IOS
if [[ "$UPLOAD_IOS" =~ ^[Yy]$ ]]; then
  read -rp "Enter path to your exported .p12 certificate file: " P12_PATH
  if [[ ! -f "$P12_PATH" ]]; then
    echo "Error: File not found at $P12_PATH"
    exit 1
  fi

  read -rsp "Enter the password for your .p12 certificate: " P12_PASS
  echo ""

  echo ""
  echo "--- App Store Connect API Key (for automated Fastlane UDID sync & profile creation) ---"
  read -rp "Upload App Store Connect API Key? (y/n): " UPLOAD_ASC
  if [[ "$UPLOAD_ASC" =~ ^[Yy]$ ]]; then
    read -rp "Enter App Store Connect API Key ID (e.g. A8M766AV9C): " ASC_KEY_ID
    read -rp "Enter App Store Connect Issuer ID (UUID): " ASC_ISSUER_ID
    read -rp "Enter path to your .p8 API key file: " P8_PATH
    if [[ ! -f "$P8_PATH" ]]; then
      echo "Error: File not found at $P8_PATH"
      exit 1
    fi

    echo "Setting App Store Connect API secrets in GitHub..."
    echo -n "$ASC_KEY_ID" | gh secret set APP_STORE_CONNECT_API_KEY_ID --repo "$REPO"
    echo -n "$ASC_ISSUER_ID" | gh secret set APP_STORE_CONNECT_API_ISSUER_ID --repo "$REPO"
    gh secret set APP_STORE_CONNECT_API_KEY_CONTENT --repo "$REPO" < "$P8_PATH"
    echo "✅ App Store Connect API credentials saved!"
  fi

  echo ""
  read -rp "Enter path to .mobileprovision file (optional if using App Store Connect API, press Enter to skip): " PROVISION_PATH
  if [[ -n "$PROVISION_PATH" ]]; then
    if [[ ! -f "$PROVISION_PATH" ]]; then
      echo "Error: File not found at $PROVISION_PATH"
      exit 1
    fi
    echo "Encoding and setting IOS_PROVISION_PROFILE_BASE64..."
    base64 -i "$PROVISION_PATH" | tr -d '\n' | gh secret set IOS_PROVISION_PROFILE_BASE64 --repo "$REPO"
  else
    echo "Notice: Skipping static profile upload. Fastlane will automatically generate and download 'com.ool.pedro AdHoc'."
  fi

  KEYCHAIN_PASS=$(openssl rand -hex 16)

  echo "Encoding and setting certificate and keychain secrets..."
  base64 -i "$P12_PATH" | tr -d '\n' | gh secret set IOS_CERTIFICATE_BASE64 --repo "$REPO"
  echo -n "$P12_PASS" | gh secret set IOS_P12_PASSWORD --repo "$REPO"
  echo -n "$KEYCHAIN_PASS" | gh secret set KEYCHAIN_PASSWORD --repo "$REPO"
  echo "✅ iOS secrets uploaded successfully!"
fi

echo ""
echo "--- Android Signing Credentials ---"
read -rp "Upload Android secrets? (y/n): " UPLOAD_ANDROID
if [[ "$UPLOAD_ANDROID" =~ ^[Yy]$ ]]; then
  read -rp "Enter path to your .jks/.keystore file: " KEYSTORE_PATH
  if [[ ! -f "$KEYSTORE_PATH" ]]; then
    echo "Error: File not found at $KEYSTORE_PATH"
    exit 1
  fi

  read -rp "Enter keystore alias (e.g. pedro-release): " KEY_ALIAS
  read -rsp "Enter keystore store password: " STORE_PASS
  echo ""
  read -rsp "Enter key password: " KEY_PASS
  echo ""

  echo "Encoding and setting Android GitHub Secrets..."
  base64 -i "$KEYSTORE_PATH" | tr -d '\n' | gh secret set ANDROID_KEYSTORE_BASE64 --repo "$REPO"
  echo -n "$STORE_PASS" | gh secret set ANDROID_KEYSTORE_PASSWORD --repo "$REPO"
  echo -n "$KEY_ALIAS" | gh secret set ANDROID_KEY_ALIAS --repo "$REPO"
  echo -n "$KEY_PASS" | gh secret set ANDROID_KEY_PASSWORD --repo "$REPO"
  echo "✅ Android secrets uploaded successfully!"
fi

echo "=========================================================="
echo "✅ Secrets configuration completed!"
echo "=========================================================="
