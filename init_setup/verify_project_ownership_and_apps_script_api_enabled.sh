#!/usr/bin/env bash
############################################################################
#  USAGE:  bash init_setup/verify_project_ownership_and_apps_script_api_enabled.sh
#
# Purpose:
#   1. Confirms the active gcloud account is Owner or Editor of PROJECT_ID
#      (from maps_config.env at the repo root).
#   2. Asks you to confirm the Apps Script API is switched on for your user
#      (a per-user setting that cannot be checked from here).
#
# Why: gcloud and clasp operations fail in confusing ways without the right
# role, and `clasp create` fails if the Apps Script API user setting is off.
############################################################################
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

assert_project_owner_or_editor() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ ERROR: $CONFIG_FILE not found. Run billing_linked_new_project.sh first."
    exit 1
  fi
  source "$CONFIG_FILE"
  if [[ -z "${PROJECT_ID:-}" ]]; then
    echo "❌ ERROR: PROJECT_ID not set in $CONFIG_FILE"
    exit 1
  fi

  local account roles
  account=$(gcloud config get-value account 2>/dev/null)

  # A failure here is usually an expired login (e.g. Workspace session control), not a missing role.
  if ! roles=$(gcloud projects get-iam-policy "$PROJECT_ID" \
      --flatten="bindings[].members" \
      --format='value(bindings.role)' \
      --filter="bindings.members:user:$account"); then
    echo "❌ ERROR: could not read the IAM policy of $PROJECT_ID as $account."
    echo "   If the message above mentions invalid_grant, run: gcloud auth login"
    exit 1
  fi

  if echo "$roles" | grep -qE 'roles/(owner|editor)'; then
    echo "✅ Access verified: $account has rights on $PROJECT_ID"
  else
    echo "❌ ERROR: $account is not owner/editor of $PROJECT_ID"
    exit 1
  fi
}

assert_apps_script_api_enabled_for_user() {
  echo "🔍 Verify that the Apps Script API is On for your user:"
  echo "   👉 Open (private window): https://script.google.com/home/usersettings"
  read -p "Is the Google Apps Script API switched On? [y/N] " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please switch it on and re-run."
    exit 1
  fi
  echo "✅ Proceeding."
}

assert_project_owner_or_editor
assert_apps_script_api_enabled_for_user
