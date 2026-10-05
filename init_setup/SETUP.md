# Setup Guide: A New Google Account to a Google Maps App on Google Sheets

Draft, to be iterated. Steps marked **(manual)** cannot be scripted. Run all scripts from the repo root,
because they read and write `maps_config.env` there.

Final result: a Google Sheet with a **Maps Demo** menu, bound to an Apps Script project that is linked
to a billing-enabled GCP project holding your Maps API key.

> **Tip: use a private (incognito) browser window for every step that involves a Google account.**
> Google Drive, Apps Script and the Cloud Console do not cope well with several Google accounts
> signed in at once. The usual symptom is "Sorry, unable to open the file" or a console page that
> shows the wrong project. In a private window, sign in as only the account you are setting up.
> Sign-ins do not persist, so repeat them in each new private window. Steps below marked
> **(private window)** are the ones that need this. See Appendix D4.

## Phase 0: Dev machine (NixOS)

**What is clasp, and why do we need it?** `clasp` ("Command Line Apps Script") is Google's official
command-line tool for Apps Script. The demo's code lives in plain JavaScript and HTML files in
`demo/` on your machine, but it only runs inside Google's Apps Script service. clasp is the bridge:
it creates the Sheet and its script project (`create_sheet.sh`) and uploads the code to it
(`push_demo.sh`), so you never copy and paste into the Apps Script editor.
It signs in to your Google account with its own login (`clasp login`, see
[Appendix B](#appendix-b-how-gcloud-clasp-and-your-google-account-fit-together)).
See [Google's clasp guide](https://developers.google.com/apps-script/guides/clasp).

1. `nix-shell` at the repo root. This provides node, gcloud and yarn, and installs clasp locally
   (`@google/clasp@3.0.3-alpha`) if missing.
2. `clasp --version` to confirm.
   - Older notes pin `@google/clasp@2.4.1` because 2.4.2+ changed `.clasp.json`/`.clasprc.json`
     handling. Only fall back to that if `clasp push` or `clasp run` misbehaves, and prefer a local
     install over `-g`.

## Phase 1: Google account (manual)

3. Create the account at https://accounts.google.com/signup. If you don't want a Gmail address, use
   https://accounts.google.com/signupwithoutgmail.
4. **(private window)** Sign in with this account in a private window, and use that window for
   the later manual steps. If you want to stay signed in, make sure it is the only Google account
   signed in to that browser.

## Phase 2: Billing (manual)

5. **(private window)** Open https://console.cloud.google.com/billing and accept the terms.
6. Create a payments profile.
   - Select **Individual**: one user. Simplest, and only that account can manage billing. Use this for a
     solo developer or a test/throwaway account.
7. Add a billing account and select payment method.
8. Ignore the auto-created "My First Project".
9. Look up the billing account ID, via the following command sequence: 
   - `gcloud auth login`
     - **(private window)** The browser it opens may be your normal one. Use the private window
       instead: add `--no-launch-browser` to print the URL (unverified for your gcloud version) and
       open that URL in the private window.
     - After authenticating in browser, you should see: You are now authenticated with the gcloud CLI!
   - `gcloud billing accounts list`
       - (outputs in format `XXXXXX-XXXXXX-XXXXXX`) -- you will need this billing_id in next step.
       - TODO: capture it in an env var via shell scriptlet --   BILLING_ID (or similar env var)

Google offers a free Maps usage tier, but billing must be enabled and calls beyond the free tier incur charges.

## Phase 3: GCP project, billing link, APIs (scripted)

10. `gcloud auth login` as the new account (the script prompts for this if you are not logged in).
11. `bash init_setup/billing_linked_new_project.sh -p <project-id> -b $BILLING_ID`
    - Project IDs are globally unique; pick something like `mapsdemo-<timestamp>`.
    - Creates the project (or reuses it if it exists), links billing, grants you `roles/owner`, and
      enables Maps JavaScript, Geocoding, API Keys, Apps Script, Sheets and Drive, plus two
      supporting APIs. Safe to re-run.
    - Writes `PROJECT_ID` to `maps_config.env` at the repo root, keeping any other entries.
12. `bash init_setup/verify_project_ownership_and_apps_script_api_enabled.sh`
    - Confirms your account is Owner/Editor of `PROJECT_ID`.
    - Then asks you to confirm the Apps Script API is **On** at
      https://script.google.com/home/usersettings **(manual toggle)**.

## Phase 4: Maps API key (scripted via gcloud, untested)

**What and why.** The demo relies on the Google Maps Geocoding API, which in turn requires 
an **API key**, and bills the usage to the GCP project that owns the key. So this phase does four things:

1. Checks the Maps APIs are enabled in the Phase 3 project (step 13).
2. Creates an API key in that project, limited to just those APIs so a leaked key can't be used
   for anything else (steps 14-15).
3. Reads the key string back (step 16).
4. Records it in `maps_config.env` (step 17). The Phase 7 push step then copies it into the
   Apps Script project's script properties, where the demo reads it at runtime. The key never
   goes into the source code or git, because `maps_config.env` is git-ignored.

**Credentials vs. API keys.** In the Cloud Console, the *Credentials* page is where you manage the
credentials your project uses to identify itself to Google. We need only one type, an **API key**.
See [Appendix A](#appendix-a-credentials-vs-api-keys) for background. All steps below use `gcloud`,
so you do not need the Credentials page. It only lists keys and is empty until a key exists.

The commands below use `$PROJECT_ID`. From the repo root, load it from `maps_config.env` and
check it:

```
source maps_config.env && echo "PROJECT_ID=$PROJECT_ID"
```

This sets the variable for the current shell only, so repeat it in any new terminal. If the echo
shows an empty value, `maps_config.env` is missing `PROJECT_ID` (Phase 3 writes it).

13. Confirm the APIs the demo calls were enabled in Phase 3:

    ```
    gcloud services list --enabled --project="$PROJECT_ID" | grep -iE "maps|geocod"
    ```

    Expected output includes:
    - `maps-backend.googleapis.com` (Maps JavaScript API: the map dialog, in the browser) and
    - `geocoding-backend.googleapis.com` (Geocoding API: address to lat/lng, on the server).

    The code is in [`demo/Code.js`](../demo/Code.js) and
    [`demo/MapDialog.html`](../demo/MapDialog.html).

    If either is missing, enable it (already-enabled services are unaffected):

    ```
    gcloud services enable maps-backend.googleapis.com geocoding-backend.googleapis.com \
      --project="$PROJECT_ID"
    ```

14. Enable the API that manages keys. Phase 3 already does this, so this is only a check:

    ```
    gcloud services enable apikeys.googleapis.com --project="$PROJECT_ID"
    ```

15. Create the key, restricted to the two APIs the demo uses:

    ```
    gcloud services api-keys create --project="$PROJECT_ID" --display-name="maps-demo" \
      --api-target=service=maps-backend.googleapis.com \
      --api-target=service=geocoding-backend.googleapis.com
    ```

    No application restriction (website/IP) is set, on purpose: geocoding calls come from Google's
    servers and the map dialog's calls from a Google-hosted domain, so a referrer restriction
    such as `https://script.google.com/*` is likely to cause `REQUEST_DENIED`
    (unverified).

16. Read back the key string:

    ```
    KEY_NAME=$(gcloud services api-keys list --project="$PROJECT_ID" \
      --filter="displayName=maps-demo" --format="value(name)")
    gcloud services api-keys get-key-string "$KEY_NAME" --format="value(keyString)"
    ```

17. Add it to `maps_config.env` (the push step fails without it). This reads the key straight from
    gcloud into the file, so you never paste or display it. It uses `$KEY_NAME` from step 16, so
    rerun step 16's first command if you are in a new terminal:

    ```
    echo "MAPS_API_KEY=\"$(gcloud services api-keys get-key-string \
      "$KEY_NAME" --format='value(keyString)')\"" >> maps_config.env
    ```

    Running it twice appends a duplicate line. The last one wins when the file is sourced, but you
    can remove extras with `sed -i '/^MAPS_API_KEY=/d' maps_config.env` and run it again.

    Treat the key as a secret. Do not paste it into chat or commit it.

Reference: https://developers.google.com/maps/gmp-get-started

## Phase 5: OAuth consent screen (manual)

18. **(private window)** Configure the consent screen (Google Auth platform) for your project:
    `https://console.developers.google.com/auth/branding?project=<project-id>`
    - First use opens a 4-step wizard (**Get Started**): App Information (app name, support email),
      Audience, Contact Information, Finish (accept the policy, then **Create**).
    - In the **Audience** step choose the user type. **External** allows any Google accounts you
      list as test users. **Internal** allows only accounts in your own Workspace organization and
      needs no test users or verification. The publishing status is not set in the wizard.
    - After creation, open **Audience** in the left menu. 
      - A new External app should show **Testing** (unverified). Leave it there and do not click **Publish app**. 
        - Under **Test users**, add your account and anyone else who will try the demo.
    - **Data Access**: scopes. Optional while the app is in Testing and used only by test users.
    - This screen only takes effect once the script is linked to the project (step 22). See
      [Appendix C](#appendix-c-how-test-users-authenticate-oauth) for how the pieces fit.
19. If you later see "insufficient permissions", add the needed scopes to `appsscript.json`
    `oauthScopes`, for example `https://www.googleapis.com/auth/spreadsheets`,
    `https://www.googleapis.com/auth/script.external_request`.
    - Note that the repo's current `appsscript.json` declares none.

## Phase 6: Create the sheet and script

20. `clasp login` (sign in as the same account). **(private window)** clasp prints an
    authorization URL. Open that URL in the private window. The redirect goes to
    `http://localhost:<port>` on your machine, so any browser works. `create_sheet.sh` does this
    automatically if `~/.clasprc.json` is missing.
21. `bash init_setup/create_sheet.sh [-D]`
    - Runs `clasp create --type sheets` in a temp directory.
    - Reads `SCRIPT_ID` and the sheet's `parentId`, and saves `SCRIPT_ID`, `SHEET_ID`, `SHEET_URL`
      to `maps_config.env`.
    - `-D` prints debug output.
    - For how the Sheet, script, GCP project and local code relate, see
      [Appendix D](#appendix-d-sheets-scripts-and-projects-what-is-bound-to-what).
22. **(manual, private window)** At the script's pause, link the script to your GCP project:
    - Open `SHEET_URL` signed in only as the account that created it. With several Google accounts
      signed in you may get "unable to open the file" (see Appendix D4).
    - Then go to Extensions, then Apps Script, then Project Settings, then
      Google Cloud Platform (GCP) Project, then **Change project**.
    - Paste the GCP project number the script printed.
    - Google says you need the Project Browser and OAuth Config Editor roles on the project (Owner
      should cover this), and that you can't pick a project Apps Script created automatically.
    - Until you do this, the script uses an auto-created project whose consent screen you can't
      edit, so your Phase 5 settings (including Test users) are not used. Users who already
      authorized must re-authorize after the switch.
    - Press Enter in the terminal when done.

## Phase 7: Push the demo code (final step)

The demo is plain JavaScript and HTML in `demo/`, so there is no build step.

23. **First push:** `bash init_setup/push_demo.sh`
    - Requires `SCRIPT_ID` and `MAPS_API_KEY` in `maps_config.env`.
    - Clones the (empty) script, copies in `demo/Code.js`, `Geocode.js`, `MapDialog.html` and
      `appsscript.json`, adds a temporary `Init.js`, and runs `clasp push --force`.
    - `Init.js` stores the Maps key in the script's **script properties** the first time the Sheet
      is opened.
    - **Security: after this push your Maps key is in the script source, in plain text.** Anyone
      who can open the Sheet can read the script, because people with view access to a Sheet can
      also view its bound script. **Step 25 removes it and is not optional.** Do not share the
      Sheet, and do not skip step 25.
    - `--dry-run` assembles the files and lists them without pushing.
24. **(private window)** Open the Sheet and reload. A **Maps Demo** menu should appear.
    - Type an address in a cell, for example `1600 Amphitheatre Parkway, Mountain View, CA`.
    - Select that cell, then **Maps Demo, Geocode selected cell**. The first time, nothing is
      geocoded: see "First-use authorization" below, then run the menu item again. The cells to
      the right then fill with the formatted address, latitude and longitude.
    - Select the cell again, then **Maps Demo, Show selected cell on map**. A dialog shows a map
      with a marker.
    - If the key is missing you will see "GOOGLE_MAPS_API_KEY is not set". Opening the Sheet should
      have run `Init.js`. If it did not (unverified), add the property by hand: Apps Script,
      Project Settings, **Script Properties**, name `GOOGLE_MAPS_API_KEY`, value your key.

    **First-use authorization.** The first time anyone runs a menu item, Google asks them to
    approve the script. Observed on a real setup, in this order:
    1. A brief message, **"Authorization is required for this script to run"**. The menu item stops
       here. It does not continue after you approve, so you run it again in step 5.
    2. A Google dialog: **"Google hasn't verified this app. You've been given access to an app
       that's currently being tested."** This is the Testing-mode consent screen from Phase 5 and
       means your account is on the Test users list and the script is linked to your project
       (step 22). The dialog offers two buttons, **Back to safety** and **Continue**. Click
       **Continue**. **Back to safety** cancels the authorization, and the menu items will not run.
    3. Choose your account if asked.
    4. A permissions page lists what the script wants. Leave **every box ticked** and click
       **Continue** or **Allow**. If you untick one, a later run fails with "Authorization is
       required to perform that action".
    5. Back in the Sheet, run the menu item again.

    The permissions page (observed) is titled "<your app name> wants access to your Google Account"
    and lists three permissions, each matched to the code that needs it:

    | Permission shown | Used by |
    |---|---|
    | See, edit, create, and delete all your Google Sheets spreadsheets | Reading the selected cell and writing the results |
    | Connect to an external service | Calling the Geocoding API (`UrlFetchApp`) |
    | Display and run third-party web content in prompts and sidebars | The map dialog |

    The app name is the one you entered on the consent screen in Phase 5. The page says it cannot
    show Privacy Policy or Terms of Service links, because none are set. That is fine while testing.

    If the dialog instead says **"Access blocked"** or **"Error 403: access_denied"**, your account
    is not on the Test users list (Phase 5, step 18) or the script is not yet linked to the project
    (step 22). Fix that and try again. (Expected from Google's docs, not observed.)

    **Viewing the log (did `Init.js` work?).** The demo writes `console.log` lines. Open the Sheet
    first so there is something to read, then use either:
    - **Apps Script editor:** open the script, click **Executions** in the left sidebar (clock
      icon), and open the `onOpen` row to see its log lines.
    - **Command line:** `bash init_setup/logs.sh` (add `--watch` to follow new lines). It also
      prints Cloud audit entries for the project, so filter for the demo's lines:
      `bash init_setup/logs.sh | grep -E "Init.js|onOpen|Geocod|geocodeSel|showMapDialog"`

    What to look for after the first reload of the Sheet:

    ```
    Init.js: stored GOOGLE_MAPS_API_KEY in script properties
    onOpen: GOOGLE_MAPS_API_KEY is set (length 39)
    ```

    If `onOpen` says the key is **NOT set**, `Init.js` did not run: add the property by hand (see
    above). The log never contains the key or the addresses, only status information such as
    `Geocoding API: HTTP 200, status OK` or `status REQUEST_DENIED, message: ...`.
    Logs are stored in the linked GCP project (step 22), so they may take a minute to appear.
    `init_setup/logs.sh` was verified to show these lines on a real setup. The Executions page is
    not yet verified.
25. **Second push (required for security):** `bash init_setup/push_demo.sh --update`
    - Pushes `demo/` without `Init.js`, which deletes `Init.js` and the key from the script source.
      The key then lives only in **script properties**, which are not shown in the source.
    - The script checks the result and prints `Verified: Init.js is gone`. If it prints an error,
      run it again. You can also look in the Apps Script editor: there must be no `Init` file.
    - Run it only after step 24 shows the menu works and the log says the key was stored. If you
      run it earlier and the key was never stored, add it by hand under Project Settings, **Script
      Properties** (step 24).
    - Reload the Sheet and repeat the checks in step 24.
    - **Use `--update` for every later push** (for example after editing `demo/`). The key is
      already in script properties, so the plain first-push mode is only needed for a new Sheet
      and script. The two pushes are one-time and different: the first adds `Init.js`, the second
      removes it.

## Phase 8: Control cost (recommended)

Maps calls are billed to your project. Google gives a free monthly usage tier, but heavy use costs
money, so set up alerts and avoid wasted calls. Current prices:
[Maps Platform pricing](https://mapsplatform.google.com/pricing/).

26. **Create a budget alert** (untested). Look up your billing account ID with
    `gcloud billing accounts list`, then:

    ```
    source maps_config.env
    gcloud billing budgets create --billing-account=<BILLING_ID> --display-name="maps-demo" \
      --budget-amount=10USD --filter-projects="projects/$PROJECT_ID" \
      --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0
    ```

    - The flags match `gcloud billing budgets create --help`. Change the amount to suit.
    - **A budget only sends notifications. It does not stop spending or switch off the API.**
    - It may need the Cloud Billing Budget API enabled
      (`gcloud services enable billingbudgets.googleapis.com --project="$PROJECT_ID"`) and a role
      such as Billing Account Administrator on the billing account (both unverified).
    - Alerts are emailed to billing account admins by default (believed; the command has
      `--disable-default-iam-recipients` to turn that off).
27. **Do not geocode the same address twice.** The demo geocodes on every click, which is fine for
    trying it out. In a real app:
    - write the result next to the address, as the demo does, and skip rows that already have one;
    - keep the address you geocoded (or a hash of it) beside the result, so you geocode again only
      when the address changes.
28. **Optional: cap daily requests.** In the Cloud Console, open the Geocoding API's **Quotas** page
    and lower the daily request limit, so a runaway script fails instead of running up charges.
    (Wording and location of this setting are unverified.)

## Known issues and gaps

- Storing the key with a temporary `Init.js` relies on top-level code running when the Sheet opens.
  This worked on the test setup (confirmed in the log). Step 24 keeps a manual fallback.
- A trimmed API list in `billing_linked_new_project.sh` has not been run on a brand-new project.

## Reset

`. init_setup/full_log_out.sh` revokes and deletes the local gcloud and clasp credentials
(`~/.config/gcloud`, `~/.clasprc.json`). It does not touch your browser: sign out of Google there
yourself, or use a private window.
Delete the Google account at https://myaccount.google.com/deleteaccount.

## Appendix A: Credentials vs. API keys

In the Cloud Console, **Credentials** is the umbrella page for the different ways of proving who is
calling a Google API. An API key is one type of credential. The **+ Create credentials** button is a
menu of those types, which is why you pick **API key** from it.

| Credential type | Identifies | Used for |
|---|---|---|
| **API key** | Your *project* (no user) | Billing and quota for public-data APIs like Maps and Geocoding |
| **OAuth client ID** | Your *app*, asking a *user* for consent | Accessing a user's data, such as their Sheets |
| **Service account** | A *robot* identity | Server-to-server access with no user |

Maps geocoding needs only an API key. Nobody's private data is involved, so Google just needs to know
which project to bill. Reading and writing the user's sheet goes through Apps Script's own OAuth
consent flow, which Phase 5 (the consent screen) configures, so no OAuth client ID is created by hand.

## Appendix B: How gcloud, clasp and your Google account fit together

### B1. Two tools, two logins, two token stores

`gcloud` and `clasp` are separate programs. You sign in to the same Google account with each, but
each keeps its own token file and talks to different Google APIs. Logging in to one does not log
you in to the other.

```
 You (e.g. chris@example.org)
   │
   │  browser sign-in + consent screen, once per tool
   │
   ├────────────────────────────────┬─────────────────────────────────┐
   ▼                                ▼                                 ▼
 gcloud auth login              clasp login                  gcloud auth application-
   │                                │                        default login (not used here)
   ▼                                ▼
 ~/.config/gcloud/              ~/.clasprc.json
   credentials.db                  token.access_token   (short-lived)
     (refresh token)               token.refresh_token  (long-lived)
   access_tokens.db                token.expiry_date
     (cached access tokens)
   │                                │
   ▼                                ▼
 Google Cloud APIs              Apps Script API + Drive API
 (projects, billing, services,  (create the script, push code,
  IAM, API keys)                 find the sheet)
   │                                │
   ▼                                ▼
 used by init_setup/*.sh        used by create_sheet.sh,
 and the Phase 3-4 commands     (Phases 6-7)
```

- **Refresh token vs. access token:** the refresh token is the durable proof you signed in. Each
  tool exchanges it for an access token that expires (about an hour). Scripts that read the
  access token directly can fail once it expires.
- **Different scopes:** gcloud's token is for Cloud APIs. clasp's token is for Apps Script and
  Drive. A token from one tool is not accepted for the other tool's APIs.
- **Both are secrets.** Anyone with these files can act as you. They are not in the repo, and
  `.clasprc.json` is git-ignored.
- **Clearing them:** `init_setup/full_log_out.sh` deletes both token stores (and also your Firefox
  profile, so read it before running it). Logging out of one tool only: `gcloud auth revoke` or
  `clasp logout`.
- **clasp credential layout changed between versions.** clasp 2.x stored `tokens.default.*`;
  clasp 3.x stores `token.*` (as above). Scripts that read the file must match the installed
  version.

### B2. What lives where: Google account structure

```
 Google account (chris@example.org)
   │
   ├── owns ──► Billing account ─────── pays for ───────────┐
   │              (payment method)                           │
   │                                                         ▼
   ├── owns ──► GCP project (e.g. my-maps-demo) ◄── billing linked here
   │              │  - APIs enabled: Maps JS, Geocoding, API Keys, Sheets, ...
   │              │  - API key (restricted to the Maps APIs)
   │              │  - OAuth consent screen
   │              ▲
   │              │ "Change project" link (manual step in Phase 6)
   │              │
   └── owns ──► Google Sheet ── bound to ──► Apps Script project (SCRIPT_ID)
                  (SHEET_ID)                    - your pushed code
                                                - script property: GOOGLE_MAPS_API_KEY
```

- **Billing account** holds the payment method. It is not the same thing as a project.
- **GCP project** is the container for APIs, the API key and quota, and the unit that gets billed.
- **Sheet and Apps Script project** are separate objects in Drive. The script is bound to the
  sheet, and linking it to the GCP project is what lets Maps calls be billed.
- **Where each ID is recorded:** `PROJECT_ID`, `SCRIPT_ID`, `SHEET_ID`, `SHEET_URL` and
  `MAPS_API_KEY` all go in the git-ignored `maps_config.env`.

### B3. clasp's files, and where permissions live

"Scopes" means two different things in this setup, kept in different files.

| File | Where | Holds | Secret? |
|---|---|---|---|
| `.clasp.json` | Project folder, git-ignored (`create_sheet.sh` makes one in a temp directory) | `scriptId`, `rootDir`, `parentId` | No |
| `~/.clasprc.json` | Your home directory | Your login: tokens, the granted `scope` list, clasp's OAuth client settings | **Yes** |
| `appsscript.json` | `demo/appsscript.json`, and inside the script project | The app's time zone and runtime, and optionally its `oauthScopes` | No |

**`.clasp.json` has no permissions.** It only says which script to talk to. Example:

```
{ "scriptId": "<SCRIPT_ID>", "rootDir": "<folder>", "parentId": ["<SHEET_ID>"] }
```

`parentId` is the ID of the Sheet the script is bound to (see Appendix D), as a one-item array.

**`~/.clasprc.json` holds clasp's permissions.** The `token.scope` field lists what clasp may do on
your behalf. It was set by `clasp login` and, on this machine, contained: `script.projects`,
`script.deployments`, `script.webapp.deploy`, `drive.file`, `drive.metadata.readonly`,
`service.management`, `logging.read`, `cloud-platform`, `userinfo.email`, `userinfo.profile` and
`openid`. A Google API that needs a scope not in this list (for example `script.processes`)
answers "insufficient authentication scopes". The fix is a new `clasp login` that requests more
scopes, not a change to your project.

**`appsscript.json` holds the app's permissions**, the ones your test users approve. By
default it has no `oauthScopes`, and Apps Script works them out from the code. See step 19.

**Does setting up OAuth in Phase 5 change `~/.clasprc.json`? No.**
- Only `clasp login` writes that file. It uses clasp's own OAuth client, so your consent screen and
  Test users list are not involved.
- The consent screen from Phase 5 is shown to people who authorize the *demo* (Appendix C1).
- The one link between them is `clasp login --creds <file>`. With a JSON file downloaded from an
  OAuth client in your own GCP project, clasp logs in through that client, and your consent
  screen then applies to the developer login too. This setup does not use it.
- Access tokens expire (about an hour). clasp renews them from the refresh token when it runs and
  updates the file (believed, not checked). If the refresh token is revoked, run `clasp login`
  again.

## Appendix C: How test users authenticate (OAuth)

Three separate OAuth flows appear in this setup. Only the last one involves your test users and your
consent screen.

### C1. A test user authorizes the demo in the Sheet

Simplified. The step marked (inferred) is not spelled out in Google's docs.

```
 Test user            Sheet + Apps Script            Google authorization server
 (browser)            (script.google.com)            (accounts.google.com)
    │                        │                                 │
 1. │ open the Sheet, choose │                                 │
    │ Maps Demo > item ─────►│                                 │
    │                        │ 2. the script needs a scope     │
    │                        │    this user has not granted    │
    │◄── "Authorization required" dialog                       │
 3. │ Continue ───────────────────────────────────────────────►│
    │                        │                                 │ 4. looks up the consent screen
    │                        │                                 │    of the LINKED GCP project:
    │                        │                                 │    app name, scopes, and (in
    │                        │                                 │    Testing) the Test users list
    │◄──────────────── 5a. not a test user: access denied ─────┤
    │◄──────────────── 5b. test user: "app not verified" ──────┤
    │                        │                                 │    warning + the scope list
 6. │ Advanced > Go to app > Allow ───────────────────────────►│
    │                        │◄─ 7. grant delivered to Apps    │
    │                        │      Script (inferred: no       │
    │                        │      redirect URL is registered │
    │                        │      by you)                    │
    │◄── 8. the menu item runs                                 │
```

Where each setting comes from:

| In the flow | Defined by |
|---|---|
| Name on the consent dialog | The **Cloud project name** (Google's docs: the project name, not the script name, identifies the script) |
| Who is allowed (5a / 5b) | **Audience, Test users** in the Google Auth platform |
| Scope list in the dialog | Inferred from the code, or `oauthScopes` in `appsscript.json` |
| "Not verified" warning | Publishing status **Testing** (never submitted for verification) |
| Where the response goes | Apps Script, not a URL you configure |

Observed on a real run (steps 2, 3 and 5b in the diagram): a brief "Authorization is required for
this script to run", then "Google hasn't verified this app. You've been given access to an app
that's currently being tested.", with the buttons **Back to safety** and **Continue**. The way
forward is **Continue**. A user who is not on the Test users list should see an access-denied
error at that point (not observed). See step 24 for the full walkthrough.

### C2. `clasp login` (developer, once per machine)

This one uses clasp's own OAuth client, not yours. The URL and port below are from a real login.

```
 Terminal (clasp)              Your browser                Google
    │                               │                        │
 1. │ start a listener on           │                        │
    │ http://localhost:<port>       │                        │
    │ (random free port, e.g. 38015)│                        │
 2. │ print/open the auth URL ─────►│                        │
    │   client_id = clasp's client  │                        │
    │   scope     = script.projects, script.deployments,     │
    │               drive.file, cloud-platform, ...          │
    │   redirect_uri = http://localhost:<port>               │
    │                               │ 3. sign in + consent ─►│
    │                               │◄─ 4. redirect to       │
    │                               │   http://localhost:<port>/?code=...
    │◄── 5. the browser delivers the code to the listener    │
 6. │ exchange code for tokens ──────────────────────────────►│
    │◄───────────────── access token + refresh token ─────────┤
 7. │ write ~/.clasprc.json         │                        │
```

`gcloud auth login` follows the same pattern with gcloud's own client. Neither flow involves your
consent screen or your Test users list. For the token files, see Appendix B.

### C3. The three flows side by side

| Flow | Who | OAuth client (owner) | Callback | Consent screen shown |
|---|---|---|---|---|
| `gcloud auth login` | You | gcloud's built-in client | Loopback on your machine (not inspected) | gcloud's |
| `clasp login` | You | clasp's built-in client | `http://localhost:<port>` | clasp's |
| Using the demo | Test users | Apps Script's (Google-managed) | Handled by Apps Script (inferred) | **Yours**, once linked (step 22) |

### C4. What you configure, and where

| Setting | Where | Controls |
|---|---|---|
| App name, support email | Console, Google Auth platform, **Branding** | Text on the consent dialog |
| User type, **Test users**, publishing status | **Audience** | Who may authorize while in Testing |
| Scopes | **Data Access**, and `appsscript.json` `oauthScopes` | What the dialog asks for |
| Which project's consent screen applies | Apps Script, Project Settings, **Change project** | Links the script to your GCP project |
| **Redirect URIs** | An **OAuth client** (Console, Google Auth platform, **Clients**) | Where Google may send the code |

Redirect URIs are on an OAuth client, not on the consent screen, and this project does not create
an OAuth client. `OAUTH.notes.txt` suggests adding `http://localhost` and `http://localhost:8080` as
redirect URIs. That applies only if you create your own OAuth client, which this setup does not.

Not verified: whether test users' grants expire after about 7 days while the app is in Testing.

## Appendix D: Sheets, scripts and projects: what is bound to what

Four different things are easy to mix up. Each has its own ID and lives in a different place.

| Object | Identified by | Lives in | In this setup |
|---|---|---|---|
| Google Sheet | `SHEET_ID` | Google Drive | `MapsDemo-<timestamp>` |
| Apps Script project ("the script") | `SCRIPT_ID` | Apps Script service | The code behind the Maps Demo menu |
| GCP project | `PROJECT_ID` and a project number | Google Cloud | Billing, APIs, the Maps key, the consent screen |
| Local code | The git repo | Your machine | `demo/` (no build step) |

### D1. Bound versus standalone scripts

A script is **container-bound** if it was created from a Sheet (or Doc, Slide, Form), and
**standalone** if it was created on its own. Per
[Google's guide](https://developers.google.com/apps-script/guides/bound), a bound script:
- can use `getActiveSpreadsheet()`, `getActiveSheet()` and `getUi()` (which the demo needs to
  add its menu and dialogs) without knowing the Sheet's ID;
- does not appear as a file in Drive and cannot be detached from its Sheet;
- shares the Sheet's owner and sharing list. **Only people who can edit the Sheet can run its
  script**, so a test user needs edit access to the Sheet as well as being a Test user (Phase 5).

The demo is container-bound.

### D2. The links, and what creates each one

```
 Local repo (demo/)
      │
      │ (2) clasp clone / clasp push        uses SCRIPT_ID
      ▼
 Apps Script project ◄──── (1) bound to ────► Google Sheet
   (SCRIPT_ID)              created together     (SHEET_ID = the script's "parentId")
      │                     by clasp create
      │ (3) "Change project" (manual, Phase 6)
      ▼
 GCP project (PROJECT_ID, project number)
   billing, enabled APIs, Maps key, consent screen
```

1. **Sheet and script: bound when created.** `clasp create --type sheets` creates the Sheet and its
   bound script together. `create_sheet.sh` runs it and records `SCRIPT_ID` from the `.clasp.json`
   that clasp writes. It then asks the Apps Script API for the script and reads `parentId`, which is
   the Sheet's ID, and records it as `SHEET_ID`.
   Google's bound-script guide says clasp can't create bound scripts, but in this setup the API
   confirms the script's `parentId` equals the Sheet's ID, so it did. Treat Google's page as
   possibly out of date on this point.
2. **Script and local code: clasp clone and push.** `push_demo.sh` clones the
   script by `SCRIPT_ID` into a temp folder, copies your built files over, and runs `clasp push`.
   Until you push, the script project holds only a default `appsscript.json`.
3. **Script and GCP project: manual.** A new script starts with a Google-managed default Cloud
   project that you cannot see or configure. Linking it to `PROJECT_ID` (Project Settings, then
   **Change project**, using the project number) is what makes your billing, API key and consent
   screen apply. See
   [Google's Cloud projects guide](https://developers.google.com/apps-script/guides/cloud-platform-projects).
   Users who authorized the script before the switch must re-authorize.

### D3. Where each ID is recorded

| Key in `maps_config.env` | Written by | When |
|---|---|---|
| `PROJECT_ID` | `init_setup/billing_linked_new_project.sh` | Phase 3 |
| `MAPS_API_KEY` | You, with `gcloud ... get-key-string` | Phase 4, step 17 |
| `SCRIPT_ID`, `SHEET_ID`, `SHEET_URL` | `init_setup/create_sheet.sh` | Phase 6, step 21 |

### D4. If the Sheet will not open

Apps Script and Drive do not support being signed in to several Google accounts at once. If you
get "Sorry, unable to open the file", the browser is probably using a different account from the
Sheet's owner. Sign out of the other accounts or use a private window signed in only as the owner.
