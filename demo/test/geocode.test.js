const test = require('node:test');
const assert = require('node:assert/strict');
const { parseGeocodeResponse } = require('../Geocode.js');

test('OK response returns address and coordinates', () => {
  const result = parseGeocodeResponse({
    status: 'OK',
    results: [{
      formatted_address: '1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA',
      geometry: { location: { lat: 37.422, lng: -122.084 } },
    }],
  });
  assert.deepEqual(result, {
    ok: true,
    status: 'OK',
    formattedAddress: '1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA',
    lat: 37.422,
    lng: -122.084,
  });
});

test('ZERO_RESULTS is reported as a failure', () => {
  const result = parseGeocodeResponse({ status: 'ZERO_RESULTS', results: [] });
  assert.equal(result.ok, false);
  assert.equal(result.status, 'ZERO_RESULTS');
});

test('REQUEST_DENIED keeps Google error message', () => {
  const result = parseGeocodeResponse({
    status: 'REQUEST_DENIED',
    error_message: 'This API project is not authorized to use this API.',
    results: [],
  });
  assert.equal(result.ok, false);
  assert.equal(result.status, 'REQUEST_DENIED');
  assert.match(result.message, /not authorized/);
});

test('OK status without a location is treated as invalid', () => {
  const result = parseGeocodeResponse({ status: 'OK', results: [{}] });
  assert.equal(result.ok, false);
  assert.equal(result.status, 'INVALID_RESPONSE');
});

test('missing or malformed input does not throw', () => {
  assert.equal(parseGeocodeResponse(null).status, 'INVALID_RESPONSE');
  assert.equal(parseGeocodeResponse({}).status, 'INVALID_RESPONSE');
});
