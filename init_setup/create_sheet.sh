#!/usr/bin/env bash
# Creates a new Google Sheet with a container-bound Apps Script project (via clasp) and records
# SCRIPT_ID, SHEET_ID and SHEET_URL in maps_config.env.
set -euo pipefail

DEBUG=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -D|--debug) DEBUG=true; shift ;;
    *) echo "❌ Unknown argument: $1"; exit 1 ;;
  esac
done

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
ensure_logged_in

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ maps_config.env not found at: $CONFIG_FILE"
  exit 1
fi

PROJECT_TITLE="MapsDemo-$(date +%s)"
TMP_DIR="$(mktemp -d /tmp/sheet_create_XXXX)"
echo "📁 Using temp working directory: $TMP_DIR"
cd "$TMP_DIR"

# === Create container-bound script with new Google Sheet ===
echo "📄 Running: clasp create --title \"$PROJECT_TITLE\" --type sheets"
clasp create --title "$PROJECT_TITLE" --type sheets > create.log

SCRIPT_ID=$(jq -r '.scriptId // empty' .clasp.json 2>/dev/null || true)
if [[ -z "$SCRIPT_ID" ]]; then
  echo "❌ Could not extract scriptId from .clasp.json"
  cat create.log
  exit 1
fi

# === The Sheet is the script's parent: read its ID from the Apps Script API ===
ACCESS_TOKEN=$(get_clasp_access_token)
SCRIPT_INFO=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://script.googleapis.com/v1/projects/${SCRIPT_ID}")
[[ "$DEBUG" == true ]] && echo "$SCRIPT_INFO" | jq

SHEET_ID=$(echo "$SCRIPT_INFO" | jq -r '.parentId // empty')
if [[ -z "$SHEET_ID" ]]; then
  echo "❌ Could not determine SHEET_ID from the Apps Script API"
  exit 1
fi

SHEET_URL="https://docs.google.com/spreadsheets/d/${SHEET_ID}"
echo "✅ SCRIPT_ID = $SCRIPT_ID"
echo "✅ SHEET_ID  = $SHEET_ID"
echo "✅ SHEET_URL = $SHEET_URL"

echo "💾 Updating $CONFIG_FILE..."
update_env_var SCRIPT_ID "$SCRIPT_ID"
update_env_var SHEET_ID "$SHEET_ID"
update_env_var SHEET_URL "$SHEET_URL"
source "$CONFIG_FILE"

# === Manual step: link the script to the real GCP project ===
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
ACCOUNT=$(gcloud config get-value account 2>/dev/null)

cat <<EOF

⚠️  MANUAL STEP REQUIRED (use a private window signed in only as $ACCOUNT)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Link this script to your GCP project so your API key and billing apply:
  GCP Project ID:     $PROJECT_ID
  GCP Project Number: $PROJECT_NUMBER

1. Open: ${SHEET_URL}?authuser=${ACCOUNT}
2. Extensions > Apps Script > Project Settings (gear)
3. Google Cloud Platform (GCP) Project > Change project
4. Paste $PROJECT_NUMBER and click Set project

EOF
read -rp "🛑 Press [ENTER] when you've finished linking the script to your GCP project..."
