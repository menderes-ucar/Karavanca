const axios = require('axios');
const db = require('../db/init');

const UA = process.env.NOMINATIM_UA || 'karavanis-dev';
const NOMINATIM_BASE = 'https://nominatim.openstreetmap.org';

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }
function roundKey(lat, lng) {
  // 3 ondalık ~ 110m; cache için yeterli
  return `${lat.toFixed(3)},${lng.toFixed(3)}`;
}

async function searchCityBbox(cityName) {
  const url = `${NOMINATIM_BASE}/search`;
  const res = await axios.get(url, {
    params: {
      q: cityName,
      format: 'json',
      limit: 1,
      addressdetails: 1,
      polygon_geojson: 0,
    },
    headers: { 'User-Agent': UA },
    timeout: 20000,
  });

  if (!Array.isArray(res.data) || res.data.length === 0) return null;

  const item = res.data[0];
  // boundingbox: [south, north, west, east] as strings
  const bb = item.boundingbox?.map(Number);
  if (!bb || bb.length !== 4) return null;

  return {
    minLat: bb[0],
    maxLat: bb[1],
    minLng: bb[2],
    maxLng: bb[3],
    displayName: item.display_name,
  };
}

async function reverseGeocode(lat, lng) {
  const key = roundKey(lat, lng);

  const cached = db.prepare(`SELECT city, district, address FROM geocode_cache WHERE key=?`).get(key);
  if (cached) return cached;

  const url = `${NOMINATIM_BASE}/reverse`;
  const res = await axios.get(url, {
    params: {
      lat,
      lon: lng,
      format: 'json',
      addressdetails: 1,
    },
    headers: { 'User-Agent': UA },
    timeout: 20000,
  });

  const addr = res.data?.address || {};
  const city =
    addr.city || addr.town || addr.village || addr.municipality || addr.county || null;
  const district =
    addr.suburb || addr.city_district || addr.district || addr.county || null;
  const address = res.data?.display_name || null;

  const out = { city, district, address };

  db.prepare(
    `INSERT OR REPLACE INTO geocode_cache(key, city, district, address, updated_at)
     VALUES(?,?,?,?, datetime('now'))`
  ).run(key, out.city, out.district, out.address);

  // Nominatim’e yük bindirmeyelim
  await sleep(900);

  return out;
}

module.exports = { searchCityBbox, reverseGeocode };
