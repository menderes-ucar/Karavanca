const axios = require('axios');

const OVERPASS = 'https://overpass-api.de/api/interpreter';

async function fetchCampsByBbox({ minLat, minLng, maxLat, maxLng }) {
  // tourism=camp_site / caravan_site / camp_pitch
  const q = `
  [out:json][timeout:25];
  (
    node["tourism"="camp_site"]["name"](${minLat},${minLng},${maxLat},${maxLng});
    way["tourism"="camp_site"]["name"](${minLat},${minLng},${maxLat},${maxLng});
    relation["tourism"="camp_site"]["name"](${minLat},${minLng},${maxLat},${maxLng});
  );
  out center tags;
  `;

  const res = await axios.post(OVERPASS, q, {
    headers: { 'Content-Type': 'text/plain' },
    timeout: 60000,
  });

  return res.data?.elements || [];
}

module.exports = { fetchCampsByBbox };
