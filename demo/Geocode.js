/**
 * Pure helper for the Geocoding API response. No Apps Script services are used here,
 * so it can be unit-tested with Node (see test/geocode.test.js).
 *
 * @param {object} json Parsed response from maps.googleapis.com/maps/api/geocode/json
 * @return {{ok: boolean, status: string, message?: string,
 *           formattedAddress?: string, lat?: number, lng?: number}}
 */
function parseGeocodeResponse(json) {
  const status = json && json.status ? json.status : 'INVALID_RESPONSE';
  if (status !== 'OK') {
    return { ok: false, status, message: (json && json.error_message) || '' };
  }
  const first = json.results && json.results[0];
  if (!first || !first.geometry || !first.geometry.location) {
    return { ok: false, status: 'INVALID_RESPONSE', message: 'No location in first result' };
  }
  return {
    ok: true,
    status,
    formattedAddress: first.formatted_address,
    lat: first.geometry.location.lat,
    lng: first.geometry.location.lng,
  };
}

// Lets Node load this file in tests. Apps Script ignores it (no `module` there).
if (typeof module !== 'undefined') {
  module.exports = { parseGeocodeResponse };
}
