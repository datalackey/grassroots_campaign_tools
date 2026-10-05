#!/usr/bin/env bash
# Pushes demo/ to the Apps Script project in maps_config.env (SCRIPT_ID).
#
#   SECURITY: the first push puts your Maps API key in the script's SOURCE (a file called
#   Init.js). Anyone who can open the Sheet can read it (people with view access to a Sheet can
#   also view its bound script). The SECOND push (--update) deletes Init.js and is NOT optional.
#
#   Step 1, first push:   bash init_setup/push_demo.sh
#       Pushes demo/ plus a temporary Init.js that stores MAPS_API_KEY in the script's
#       properties the first time the Sheet is opened.
#   Step 2, REQUIRED:     bash init_setup/push_demo.sh --update
#       Pushes demo/ only, which removes Init.js (and the key) from the script source, then
#       checks that Init.js is really gone. Run it after you have opened the Sheet once and
#       seen the Maps Demo menu (check the log, see SETUP.md step 24).
#
#   --dry-run     Assemble the files and list them without pushing anything.
set -euo pipefail

UPDATE=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--update) UPDATE=true; shift ;;
    --dry-run)   DRY_RUN=true; shift ;;
    -h|--help)   sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "❌ Unknown option: $1"; exit 1 ;;
  esac
done

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
ensure_logged_in

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Missing config file: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

if [[ -z "${SCRIPT_ID:-}" ]]; then
  echo "❌ SCRIPT_ID is not set in $CONFIG_FILE. Run init_setup/create_sheet.sh first."
  exit 1
fi
if [[ "$UPDATE" == false && -z "${MAPS_API_KEY:-}" ]]; then
  echo "❌ MAPS_API_KEY is not set in $CONFIG_FILE (see the Maps API key phase in SETUP.md)."
  exit 1
fi

TMP_DIR="$(mktemp -d /tmp/clasp_push_XXXX)"
echo "🚧 Working in: $TMP_DIR"
cd "$TMP_DIR"

echo "📥 Cloning script $SCRIPT_ID"
clasp clone "$SCRIPT_ID" >/dev/null

# Start from a clean slate so the pushed project contains exactly demo/ (plus Init.js).
find . -maxdepth 1 -type f ! -name .clasp.json -delete
cp "$DEMO_DIR"/*.js "$DEMO_DIR"/*.html "$DEMO_DIR"/appsscript.json .

if [[ "$UPDATE" == false ]]; then
  echo "🧬 Adding temporary Init.js to store the Maps key in script properties"
  KEY_LITERAL=$(jq -Rn --arg k "$MAPS_API_KEY" '$k')   # JSON string == valid JS string literal
  cat > Init.js <<EOF
function storeMapsKey() {
  PropertiesService.getScriptProperties().setProperty('GOOGLE_MAPS_API_KEY', $KEY_LITERAL);
  console.log('Init.js: stored GOOGLE_MAPS_API_KEY in script properties');
}
// Runs whenever any function in the project runs (the first one stores the key).
storeMapsKey();
EOF
fi

echo "📦 Files to push:"
ls -1 | sed 's/^/   /'

if [[ "$DRY_RUN" == true ]]; then
  echo "🧪 Dry run: nothing pushed."
  exit 0
fi

echo "🚀 Pushing"
clasp push --force

if [[ "$UPDATE" == false ]]; then
  cat <<EOF

✅ Pushed. Next:
   1. Open the Sheet (private window) and reload it. The Maps Demo menu should appear.
      Opening the Sheet runs Init.js, which stores the key in script properties.
      Check the log: bash init_setup/logs.sh | grep -E "Init.js|onOpen"

   ⚠️  2. YOU MUST NOW RUN:  bash init_setup/push_demo.sh --update
      Until you do, your Maps API key is stored in plain text in the script source
      (Init.js), visible to anyone who can open the Sheet.
EOF
else
  # Confirm that the remote project no longer contains Init.js (the Apps Script API lists
  # files without their extension). The token is fresh: clasp push just refreshed it.
  REMOTE_FILES=$(curl -s -H "Authorization: Bearer $(get_clasp_access_token)" \
    "https://script.googleapis.com/v1/projects/${SCRIPT_ID}/content" | jq -r '.files[].name' || true)
  if echo "$REMOTE_FILES" | grep -qx "Init"; then
    echo "❌ Init.js is STILL in the script source, so the key is exposed. Run this again." >&2
    exit 1
  fi
  if [[ -z "$REMOTE_FILES" ]]; then
    echo "⚠️  Could not list the script's files to verify. Check the Apps Script editor: there"
    echo "    must be no Init file."
  else
    echo "✅ Verified: Init.js is gone. The key now lives only in script properties."
  fi
fi
