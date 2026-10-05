# Extension Components

What the Campaign Tools extension adds to a Google Sheet, which source file implements each
piece, and which Google API each piece talks to. For installing it, see
[`init_setup/SETUP.md`](../init_setup/SETUP.md).

## Apps Script UI vocabulary

An Apps Script project bound to a Sheet can add several kinds of UI. This extension uses the first
three. It does **not** use a sidebar.

| Term | What it is | Used here? |
|---|---|---|
| **Custom menu** | A menu added to the Sheet's menu bar by `onOpen()`. | Yes: **📍 Campaign** |
| **Alert / prompt dialog** | A small built-in box (`ui.alert`, `ui.prompt`) with fixed buttons or one text field. | Yes |
| **Modal dialog** | A custom HTML window shown with `showModalDialog`. It blocks the Sheet until closed. | Yes: **Filter by Distance** |
| **Sidebar** | A custom HTML panel docked beside the Sheet (`showSidebar`). The Sheet stays usable. | No |

Google's guides:
- [Custom menus](https://developers.google.com/apps-script/guides/menus)
- [Dialogs and sidebars](https://developers.google.com/apps-script/guides/dialogs)
- [HTML service](https://developers.google.com/apps-script/guides/html)
  (how HTML files become dialogs)
- [Client-to-server communication](https://developers.google.com/apps-script/guides/html/communication)
  (`google.script.run`, used by the Filter dialog)
- [Properties service](https://developers.google.com/apps-script/reference/properties/properties-service)
  (where the Maps API key is stored)

Some file names in this repo say "sidebar" (for example `scripts/inject_sidebar.sh`). Those are
leftovers from an earlier design. The UI they build is the modal Filter dialog.

## Components

| Component | Source | What it does |
|---|---|---|
| **📍 Campaign menu** | `onOpen()` in [`src/Code.js`](src/Code.js) | Adds the menu with the items below. |
| **Filter By Distance** (menu item) | `showAutocompleteDialog()` in [`src/Code.js`](src/Code.js) | Opens the Filter dialog (420 x 420). |
| **Filter dialog** | [`src/FilterUI.template.html`](src/FilterUI.template.html) and [`src/FilterUICode.js`](src/FilterUICode.js) | Address typeahead, a distance slider (1-100 miles) and Submit. Runs in the browser. |
| **Add Lat/Long Info** (menu item) | `populateLatLong()` in [`src/AddLatLong.js`](src/AddLatLong.js) | Geocodes each row's address and writes latitude/longitude into the sheet. |
| **Column prompt** | [`src/AddLatLong.js`](src/AddLatLong.js) | A prompt dialog, shown only when no address column is found. |
| **Overwrite confirm** | `filterAndWriteMatches()` in [`src/Code.js`](src/Code.js) | An OK/Cancel alert when the "Filtered Results" sheet already exists. |
| **Greet, Hello** (menu items) | [`src/LatLong.ts`](src/LatLong.ts) | Test items from the TypeScript port. Likely to be removed. |

Inside the Filter dialog the HTML template also draws its own in-page alert and toast (small
messages), separate from the Apps Script alert dialogs above.

## How the pieces connect

```
 Google Sheet (browser)
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ Menu bar:  📍 Campaign                                                   │
 │              ├─ Filter By Distance ──────────┐                           │
 │              ├─ Add Lat/Long Info ─────────┐ │                           │
 │              ├─ Greet / Hello (test)       │ │                           │
 └────────────────────────────────────────────┼─┼───────────────────────────┘
                                              │ │
   Apps Script (runs on Google's servers)     │ │
   ┌──────────────────────────────────────────┼─┼─────────────────────┐
   │ onOpen()  builds the menu                │ │                     │
   │                                          │ ▼                     │
   │                          showAutocompleteDialog()                │
   │                            opens the modal Filter dialog ───────────────┐
   │                                          │                       │      │
   │ populateLatLong()  ◄─────────────────────┘                       │      │
   │   ├─ ui.prompt: which column is the address? (only if needed)    │      │
   │   ├─ UrlFetchApp ──► Geocoding API   (address -> lat/lng)        │      │
   │   └─ writes lat/lng columns, ui.alert when finished              │      │
   │                                                                  │      │
   │ getMapsApiKey()  reads GOOGLE_MAPS_API_KEY from script properties│      │
   │ getDebug()       reads the DEBUG flag                            │      │
   │ filterAndWriteMatches(lat, lng, miles)                           │      │
   │   ├─ ui.alert OK/Cancel if "Filtered Results" exists             │      │
   │   └─ writes matching rows to the "Filtered Results" sheet        │      │
   └──────────────▲───────────────────────────────────────────────────┘      │
                  │  google.script.run                                       │
                  │  (getMapsApiKey, getDebug, filterAndWriteMatches)        │
   ┌──────────────┴───────────────────────────────────────────────────────┐  │
   │ Filter dialog (HTML + JS in the browser) ◄───────────────────────────┼──┘
   │   1. asks the server for the Maps API key                            │
   │   2. loads the Maps JavaScript API, with the Places library          │
   │   3. user types an address ──► Places Autocomplete ──► lat/lng       │
   │   4. user sets the distance and clicks Submit                        │
   │   5. calls filterAndWriteMatches on the server, shows the result     │
   └──────────────────────────────────────────────────────────────────────┘
```

## Which Google API each piece calls

| Caller | Runs | API | Why |
|---|---|---|---|
| Filter dialog | In the user's browser | Maps JavaScript API, Places library | Address typeahead and lat/lng of the chosen address |
| `populateLatLong()` | Apps Script server | Geocoding API (`UrlFetchApp`) | Convert each row's address to lat/lng |
| `filterAndWriteMatches()` | Apps Script server | None (local math) | Haversine straight-line distance on stored lat/lng |

## Things worth knowing

- **Filtering uses stored lat/lng.** The Filter dialog does not geocode volunteers. Run
  **Add Lat/Long Info** first, then **Filter By Distance**.
- **The Maps key reaches the browser.** The dialog fetches the key from script properties and puts
  it in a `<script src>` URL, so the key is visible to anyone using the Sheet. This is why the key
  should be restricted to the Maps APIs (Phase 4 of [`SETUP.md`](../init_setup/SETUP.md)).
- **Two kinds of call, two environments.** Browser calls (Filter dialog) and server calls
  (geocoding) have different origins, which matters when restricting the API key by website or IP.
