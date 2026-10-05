#!/usr/bin/env bash
# Shows the Apps Script execution log (console.log output) for SCRIPT_ID in maps_config.env.
#
#   bash init_setup/logs.sh            print recent log entries
#   bash init_setup/logs.sh --watch    keep printing new entries
#   bash init_setup/logs.sh --json     raw entries
#
# Any extra options are passed to `clasp logs`. Requires the script to be linked to a standard
# GCP project (Phase 6, step 22), because that is where the logs are stored.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
ensure_clasp_logged_in

[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
if [[ -z "${SCRIPT_ID:-}" || -z "${PROJECT_ID:-}" ]]; then
  echo "❌ SCRIPT_ID and PROJECT_ID must be set in $CONFIG_FILE (run the earlier setup steps)."
  exit 1
fi

# clasp needs a .clasp.json with the script and its GCP project; make a throwaway one.
TMP_DIR="$(mktemp -d /tmp/clasp_logs_XXXX)"
printf '{"scriptId":"%s","projectId":"%s"}\n' "$SCRIPT_ID" "$PROJECT_ID" > "$TMP_DIR/.clasp.json"
cd "$TMP_DIR"

clasp logs --simplified "$@"
