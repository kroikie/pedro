#!/usr/bin/env bash
set -euo pipefail

# Configuration
PROJECT_ID="pedro-f65a6"
PROJECT_NUMBER="260654198138"
REPO="kroikie/pedro"
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"

# Allow passing service account as first argument or via environment variable
SERVICE_ACCOUNT="${1:-${SERVICE_ACCOUNT:-}}"

echo "=========================================================="
echo " Setting up Google Cloud Workload Identity Federation     "
echo " Project: ${PROJECT_ID} (${PROJECT_NUMBER})               "
echo " Repo:    ${REPO}                                         "
echo "=========================================================="

echo "1. Enabling required Google Cloud APIs..."
gcloud services enable \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  eventarc.googleapis.com \
  --project="${PROJECT_ID}"

echo "2. Resolving Service Account..."
if [[ -z "${SERVICE_ACCOUNT}" ]]; then
  echo "Looking for existing Firebase Admin SDK service account in ${PROJECT_ID}..."
  SERVICE_ACCOUNT=$(gcloud iam service-accounts list \
    --project="${PROJECT_ID}" \
    --filter="email ~ ^firebase-adminsdk" \
    --format="value(email)" 2>/dev/null | head -n 1 || true)
fi

if [[ -z "${SERVICE_ACCOUNT}" ]]; then
  SA_NAME="github-actions-distribute"
  SERVICE_ACCOUNT="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
  echo "No existing firebase-adminsdk service account found."
  echo "Using/creating dedicated service account: ${SERVICE_ACCOUNT}..."

  if ! gcloud iam service-accounts describe "${SERVICE_ACCOUNT}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
    echo "Creating service account ${SA_NAME}..."
    gcloud iam service-accounts create "${SA_NAME}" \
      --project="${PROJECT_ID}" \
      --display-name="GitHub Actions Beta Distribution"
  else
    echo "Service account ${SERVICE_ACCOUNT} already exists."
  fi
fi

echo "Selected Service Account: ${SERVICE_ACCOUNT}"

echo "Granting required distribution and Cloud Functions deployment roles..."
REQUIRED_ROLES=(
  "roles/firebaseappdistro.admin"
  "roles/serviceusage.serviceUsageConsumer"
  "roles/cloudfunctions.admin"
  "roles/run.admin"
  "roles/cloudbuild.builds.editor"
  "roles/artifactregistry.writer"
  "roles/storage.admin"
  "roles/firebase.admin"
  "roles/iam.serviceAccountUser"
)

for role in "${REQUIRED_ROLES[@]}"; do
  echo "  - Granting $role..."
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="$role" --condition=None --quiet >/dev/null
done

echo "3. Creating Workload Identity Pool: ${POOL_NAME}..."
if ! gcloud iam workload-identity-pools describe "${POOL_NAME}" --location="global" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools create "${POOL_NAME}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --display-name="GitHub Actions Pool"
else
  echo "Workload Identity Pool '${POOL_NAME}' already exists."
fi

echo "4. Creating Workload Identity Provider: ${PROVIDER_NAME}..."
if ! gcloud iam workload-identity-pools providers describe "${PROVIDER_NAME}" --workload-identity-pool="${POOL_NAME}" --location="global" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="${POOL_NAME}" \
    --display-name="GitHub Provider" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository == '${REPO}'"
else
  echo "Workload Identity Provider '${PROVIDER_NAME}' already exists."
fi

echo "5. Granting Service Account Impersonation permission to GitHub repo ${REPO}..."
gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${REPO}"

# If GitHub CLI is available, upload service account to repo secret
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  echo "Saving GCP_SERVICE_ACCOUNT secret to GitHub repository ${REPO}..."
  echo -n "${SERVICE_ACCOUNT}" | gh secret set GCP_SERVICE_ACCOUNT --repo "${REPO}"
fi

echo "=========================================================="
echo "✅ Workload Identity Federation configured successfully!"
echo "Service Account: ${SERVICE_ACCOUNT}"
echo "Provider: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"
echo "=========================================================="
