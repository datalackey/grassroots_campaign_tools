# Grassroots Campaign Tools

ACTIVE ROLE: WIKI-AUTHOR

Google Sheets extension (Apps Script, TypeScript + Webpack, deployed with clasp) that filters
volunteers by distance using the Google Maps API.

## Layout

- `init_setup/` – one-time GCP setup scripts (project + billing link, ownership check, log-out helper)
- `ui/` – TypeScript source, webpack build, and `ui/scripts/` (create sheet, push to Apps Script)
- `maps_config.env` – generated, git-ignored; holds `PROJECT_ID`, `SCRIPT_ID`, `SHEET_ID`, `SHEET_URL`, `MAPS_API_KEY`
- `README.md`, `NOTES.txt`, `OAUTH.notes.txt` – raw setup notes (source material for the setup guide)
- `DOCUMENTATION.md` – end-user documentation; `MILESTONES.md` – roadmap

## Setup flow (end to end)

1. `nix-shell` at the repo root
2. Create the Google account and billing account (manual)
3. `init_setup/billing_linked_new_project.sh -p <project-id> -b <billing-id>`
4. `init_setup/verify_project_ownership_and_apps_script_api_enabled.sh`
5. Create the Maps API key and add `MAPS_API_KEY` to `maps_config.env`
6. Configure the OAuth consent screen (Testing mode, add test user)
7. `ui/scripts/create_sheet.sh` – then link the script to the GCP project (manual)
8. `ui/scripts/push_content_to_script_by_id.sh` – final step

## Conventions

- Scripts are bash with `set -euo pipefail`; run them from the repo root.
- Never install packages globally; use `npx` or devDependencies.
- Setup instructions are iterated on; prefer accuracy, cite Google/GAS docs where possible.
