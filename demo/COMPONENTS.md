# Demo Components

What the demo adds to a Google Sheet, which file implements each piece, and which Google API each
piece calls. For installing it, see [`init_setup/SETUP.md`](../init_setup/SETUP.md).

## Apps Script UI vocabulary

An Apps Script project bound to a Sheet can add several kinds of UI. The demo uses the first three.
It does **not** use a sidebar.

| Term | What it is | Used here? |
|---|---|---|
| **Custom menu** | A menu added to the Sheet's menu bar by `onOpen()`. | Yes: **Maps Demo** |
| **Alert / prompt dialog** | A small built-in box (`ui.alert`, `ui.prompt`) with fixed buttons or one text field. | Yes, for errors |
| **Modal dialog** | A custom HTML window shown with `showModalDialog`. It blocks the Sheet until closed. | Yes: the map |
| **Sidebar** | A custom HTML panel docked beside the Sheet (`showSidebar`). The Sheet stays usable. | No |

Google's guides:
- [Custom menus](https://developers.google.com/apps-script/guides/menus)
- [Dialogs and sidebars](https://developers.google.com/apps-script/guides/dialogs)
- [HTML service](https://developers.google.com/apps-script/guides/html)
  (how HTML files become dialogs)
- [Properties service](https://developers.google.com/apps-script/reference/properties/properties-service)
  (where the Maps API key is stored)

## Components

| Component | Source | What it does |
|---|---|---|
| **Maps Demo menu** | `onOpen()` in [`Code.js`](Code.js) | Adds the menu, and logs whether the Maps key is set. |
| **Geocode selected cell** | `geocodeSelectedCell()` in [`Code.js`](Code.js) | Geocodes the address in the selected cell and writes the formatted address, latitude and longitude into the three cells to its right. |
| **Show selected cell on map** | `showMapDialog()` in [`Code.js`](Code.js) | Geocodes the selected cell on the server, then opens the map dialog. |
| **Map dialog** | [`MapDialog.html`](MapDialog.html) | Loads the Maps JavaScript API in the browser and draws a marker. |
| **Geocoding call** | `geocodeAddress()` in [`Code.js`](Code.js) | Calls the Geocoding API with `UrlFetchApp` and logs the status. |
| **Response parser** | [`Geocode.js`](Geocode.js) | Pure function `parseGeocodeResponse()`, unit-tested in [`test/geocode.test.js`](test/geocode.test.js). |
| **Manifest** | [`appsscript.json`](appsscript.json) | Time zone and runtime. It lists no scopes, so Apps Script detects them from the code. |

## How the pieces connect

```
 Google Sheet (browser)
 ┌──────────────────────────────────────────────────────────────────┐
 │ Menu bar:  Maps Demo                                             │
 │              ├─ Geocode selected cell ───────────┐               │
 │              └─ Show selected cell on map ─────┐ │               │
 └────────────────────────────────────────────────┼─┼───────────────┘
                                                  │ │
   Apps Script (runs on Google's servers)         │ │
   ┌──────────────────────────────────────────────┼─┼──────────────────┐
   │ onOpen()  builds the menu                    │ │                  │
   │                                              │ ▼                  │
   │   geocodeSelectedCell()  ◄───────────────────┼─┘                  │
   │     ├─ geocodeAddress() ─► Geocoding API (UrlFetchApp)            │
   │     └─ writes address, lat, lng next to the cell                  │
   │                                              │                    │
   │   showMapDialog()  ◄─────────────────────────┘                    │
   │     ├─ geocodeAddress() ─► Geocoding API                          │
   │     └─ opens MapDialog with the key, lat, lng and label ──────────┼──┐
   │                                                                   │  │
   │ Script properties: GOOGLE_MAPS_API_KEY                            │  │
   └───────────────────────────────────────────────────────────────────┘  │
                                                                          │
   ┌──────────────────────────────────────────────────────────────────┐   │
   │ Map dialog (HTML + JS in the browser) ◄───────────────────────────┼──┘
   │   loads the Maps JavaScript API with the key, then draws a map    │
   │   centred on the lat/lng with a marker                            │
   └───────────────────────────────────────────────────────────────────┘
```

## Which Google API each piece calls

| Caller | Runs | API | Why |
|---|---|---|---|
| `geocodeAddress()` | Apps Script server | Geocoding API (`UrlFetchApp`) | Convert an address to latitude and longitude |
| Map dialog | The user's browser | Maps JavaScript API | Draw the map and marker |

## Things worth knowing

- **The Maps key reaches the browser.** The dialog is given the key and puts it in a `<script src>`
  URL, so anyone using the Sheet can see it. This is why the key is restricted to the Maps APIs
  (Phase 4 of [`SETUP.md`](../init_setup/SETUP.md)).
- **Two kinds of call, two environments.** Browser calls (the map) and server calls (geocoding) have
  different origins, which matters when restricting the key by website or IP.
- **Logs never contain the key or addresses.** They record statuses only, for example
  `Geocoding API: HTTP 200, status OK`. See `SETUP.md` step 24 for how to read them.
- **Cell text is escaped** before it goes into the dialog's `<script>`, so an address cannot close
  the tag.
