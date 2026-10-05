#!/usr/bin/env bash
# Creates (or reuses) a GCP project, links billing, grants you Owner, and enables the APIs the
# Maps demo needs. Safe to re-run: an existing project is reused and maps_config.env is updated
# in place, not overwritten.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

usage() {
  echo "Usage: $0 -p <project-id> -b <billing-id>"
  echo "  Find your billing id with: gcloud billing accounts list"
}

PROJECT_ID=""
BILLING_ID=""
while getopts "p:b:h" opt; do
  case "$opt" in
    p) PROJECT_ID="$OPTARG" ;;
    b) BILLING_ID="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_ID" || -z "$BILLING_ID" ]]; then
  echo "❌ Both PROJECT_ID and BILLING_ID are required."
  usage
  exit 1
fi

ensure_gcloud_logged_in

# === Create the project, or reuse it if it already exists ===
if gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
  echo "♻️  Project $PROJECT_ID already exists — reusing it."
else
  echo "Creating Google Cloud project: $PROJECT_ID..."
  gcloud projects create "$PROJECT_ID"
fi

echo "Setting active project to: $PROJECT_ID..."
gcloud config set project "$PROJECT_ID"

echo "Linking billing account $BILLING_ID to project $PROJECT_ID..."
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ID"

ACCOUNT=$(gcloud config get-value account 2>/dev/null)
echo "🔓 Granting OWNER role to $ACCOUNT..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="user:$ACCOUNT" \
  --role="roles/owner" >/dev/null

# === Enable only what the demo needs ===
APIS=(
  maps-backend.googleapis.com        # Maps JavaScript API (map dialog, browser side)
  geocoding-backend.googleapis.com   # Geocoding API (address to lat/lng, server side)
  apikeys.googleapis.com             # lets gcloud create and restrict the Maps API key
  script.googleapis.com              # Apps Script
  sheets.googleapis.com
  drive.googleapis.com
  cloudresourcemanager.googleapis.com
  serviceusage.googleapis.com
)
for API in "${APIS[@]}"; do
  echo "🔌 Enabling $API..."
  gcloud services enable "$API" --project="$PROJECT_ID" --quiet
done

update_env_var PROJECT_ID "$PROJECT_ID"
echo "💾 Saved PROJECT_ID to $CONFIG_FILE"
echo "✅ Project $PROJECT_ID is ready."
