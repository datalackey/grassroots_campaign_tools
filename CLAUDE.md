# Google Maps on Google Sheets: setup guide and demo

ACTIVE ROLE: WIKI-AUTHOR

A generic, step-by-step guide to set up a Google account, billing, a Maps API key and an Apps
Script project, plus a small demo (Geocoding and a Maps JavaScript dialog) pushed to a Sheet with
clasp. The guide is the product. Keep it generic and do not describe any specific downstream app.

## Layout

- `init_setup/SETUP.md`: the guide. Phases 0-7, then appendices A-D (credentials vs API keys,
  gcloud/clasp token stores, OAuth flows, how sheets/scripts/projects bind).
- `init_setup/*.sh`: scripts the guide runs. `utils.sh` holds shared helpers and is sourced by
  the others.
- `demo/`: Apps Script code (`Code.js`, `Geocode.js`, `MapDialog.html`, `appsscript.json`) with
  unit tests in `demo/test/`. No build step. `demo/COMPONENTS.md` describes it.
- `OAUTH.notes.txt`: raw OAuth notes kept as reference.
- `maps_config.env`: generated, git-ignored. Holds `PROJECT_ID`, `MAPS_API_KEY`, `SCRIPT_ID`,
  `SHEET_ID`, `SHEET_URL`. Never print or commit it.

## Setup flow (see SETUP.md for detail)

1. `nix-shell` at the repo root.
2. Create the Google account and billing account (manual, private window).
3. `init_setup/billing_linked_new_project.sh -p <project-id> -b <billing-id>`
4. `init_setup/verify_project_ownership_and_apps_script_api_enabled.sh`
5. Create the Maps API key with gcloud and store it in `maps_config.env`.
6. Configure the OAuth consent screen (Testing mode, add test users).
7. `init_setup/create_sheet.sh`, then link the script to the GCP project (manual).
8. `init_setup/push_demo.sh`, test the menu, then `init_setup/push_demo.sh --update`.
   The second push is required: it removes the temporary `Init.js` that holds the key.

## Conventions

- Scripts are bash with `set -euo pipefail`; run them from the repo root.
- Never install packages globally; use `npx` or devDependencies.
- Never put the API key in logs, docs or commits. Logging records statuses only.
- Guide wording: say what is verified and what is not. Mark guesses "unverified".
- Markdown lines stay under 100 characters (tables excepted).
