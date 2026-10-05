#!/usr/bin/env bash
# Shared helpers for the init_setup scripts. Source this file; do not run it.

GIT_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
CONFIG_FILE="$GIT_ROOT/maps_config.env"
DEMO_DIR="$GIT_ROOT/demo"

require_clasp() {
  if ! command -v clasp >/dev/null 2>&1; then
    echo "❌ clasp not found on PATH. Run 'nix-shell' at the repo root first." >&2
    exit 1
  fi
}

ensure_gcloud_logged_in() {
  echo "🔐 Checking gcloud login..."
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "🔓 Not logged in to gcloud — invoking login (use a private window)..."
    gcloud auth login
  else
    echo "✅ gcloud: $(gcloud config get-value account 2>/dev/null)"
  fi
}

ensure_clasp_logged_in() {
  require_clasp
  echo "🔐 Checking clasp login..."
  if [[ ! -f "$HOME/.clasprc.json" ]]; then
    echo "🔓 Not logged in to clasp — invoking login (open the URL in a private window)..."
    clasp login
  else
    echo "✅ clasp is already logged in"
  fi
}

ensure_logged_in() {
  ensure_gcloud_logged_in
  ensure_clasp_logged_in
}

# Print clasp's access token. clasp 3.x stores it at .token.access_token in ~/.clasprc.json,
# clasp 2.x at .tokens.default.access_token. The token expires (about an hour), so call this
# right after a clasp command, which refreshes and saves it.
get_clasp_access_token() {
  local token
  token=$(jq -r '.token.access_token // .tokens.default.access_token // empty' "$HOME/.clasprc.json")
  if [[ -z "$token" ]]; then
    echo "❌ No access token in ~/.clasprc.json. Run: clasp login" >&2
    return 1
  fi
  echo "$token"
}

# Set KEY="value" in maps_config.env, replacing an existing line or appending a new one.
update_env_var() {
  local key="$1" value="$2"
  touch "$CONFIG_FILE"
  if grep -q "^${key}=" "$CONFIG_FILE"; then
    sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$CONFIG_FILE"
  else
    echo "${key}=\"${value}\"" >> "$CONFIG_FILE"
  fi
}
