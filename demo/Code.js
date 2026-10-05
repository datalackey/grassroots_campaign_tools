/**
 * Maps demo: shows the two ways a Google Maps API key is used from a Sheet.
 *   1. Server side: Geocoding API called with UrlFetchApp (menu item 1).
 *   2. Browser side: Maps JavaScript API in a dialog (menu item 2).
 * The key lives in script properties (GOOGLE_MAPS_API_KEY), set by the push script.
 */

function onOpen() {
  // Logs whether the key made it into script properties (never the key itself).
  const key = PropertiesService.getScriptProperties().getProperty('GOOGLE_MAPS_API_KEY');
  console.log('onOpen: GOOGLE_MAPS_API_KEY ' + (key ? 'is set (length ' + key.length + ')' : 'is NOT set'));
  SpreadsheetApp.getUi()
    .createMenu('Maps Demo')
    .addItem('Geocode selected cell', 'geocodeSelectedCell')
    .addItem('Show selected cell on map', 'showMapDialog')
    .addToUi();
}

function getMapsApiKey() {
  const key = PropertiesService.getScriptProperties().getProperty('GOOGLE_MAPS_API_KEY');
  if (!key) throw new Error('GOOGLE_MAPS_API_KEY is not set in script properties.');
  return key;
}

/** Calls the Geocoding API from Apps Script's servers. Returns parseGeocodeResponse(). */
function geocodeAddress(address) {
  const url = 'https://maps.googleapis.com/maps/api/geocode/json?address=' +
    encodeURIComponent(address) + '&key=' + encodeURIComponent(getMapsApiKey());
  const response = UrlFetchApp.fetch(url, { muteHttpExceptions: true });
  const result = parseGeocodeResponse(JSON.parse(response.getContentText()));
  // Log the outcome only: not the address (personal data) and not the URL (it contains the key).
  console.log('Geocoding API: HTTP ' + response.getResponseCode() + ', status ' + result.status +
    (result.message ? ', message: ' + result.message : ''));
  return result;
}

/** Reads the address in the selected cell and writes formatted address, lat, lng to its right. */
function geocodeSelectedCell() {
  const ui = SpreadsheetApp.getUi();
  const cell = SpreadsheetApp.getActiveRange().getCell(1, 1);
  const address = String(cell.getValue()).trim();
  if (!address) {
    ui.alert('Select a cell that contains an address first.');
    return;
  }

  console.log('geocodeSelectedCell: cell ' + cell.getA1Notation());
  const result = geocodeAddress(address);
  if (!result.ok) {
    ui.alert('Geocoding failed: ' + result.status + (result.message ? '\n' + result.message : ''));
    return;
  }

  cell.offset(0, 1, 1, 3).setValues([[result.formattedAddress, result.lat, result.lng]]);
  console.log('geocodeSelectedCell: wrote 3 cells next to ' + cell.getA1Notation());
}

/** Geocodes the selected cell on the server, then draws it on a map in the browser. */
function showMapDialog() {
  const ui = SpreadsheetApp.getUi();
  const address = String(SpreadsheetApp.getActiveRange().getCell(1, 1).getValue()).trim();
  if (!address) {
    ui.alert('Select a cell that contains an address first.');
    return;
  }

  const result = geocodeAddress(address);
  if (!result.ok) {
    ui.alert('Geocoding failed: ' + result.status + (result.message ? '\n' + result.message : ''));
    return;
  }

  console.log('showMapDialog: opening dialog');
  const template = HtmlService.createTemplateFromFile('MapDialog');
  // "<" is escaped so cell text can never close the <script> tag in the dialog.
  template.dataJson = JSON.stringify({
    apiKey: getMapsApiKey(),
    lat: result.lat,
    lng: result.lng,
    label: result.formattedAddress,
  }).replace(/</g, '\\u003c');
  ui.showModalDialog(template.evaluate().setWidth(520).setHeight(440), 'Map');
}
