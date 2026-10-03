ensure_logged_in() {
  echo "🔐 Checking gcloud login..."
  if ! gcloud auth list --format="value(account)" | grep -q .; then
    echo "🔓 Not logged in to gcloud — invoking login..."
    gcloud auth login
  else
    echo "✅ Already logged in to gcloud"
  fi

  echo "🔐 Checking clasp login..."
  if [[ ! -f "$HOME/.clasprc.json" ]]; then
    echo "🔓 Not logged in to clasp — invoking login..."
    clasp login
  else
    echo "✅ Already logged in to clasp"
  fi
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
