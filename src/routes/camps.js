const express = require('express');
const router = express.Router();

const db = require('../db/init');
const { fetchCampsByBbox } = require('../services/overpass');
const { searchCityBbox, reverseGeocode } = require('../services/geocode');

function parseBbox(bboxStr) {
  const parts = (bboxStr || '').split(',').map(Number);
  if (parts.length !== 4 || parts.some(n => Number.isNaN(n))) return null;
  return { minLat: parts[0], minLng: parts[1], maxLat: parts[2], maxLng: parts[3] };
}

function elementToRow(el) {
  const tags = el.tags || {};
  const lat = el.type === 'node' ? el.lat : (el.center?.lat ?? null);
  const lng = el.type === 'node' ? el.lon : (el.center?.lon ?? null);
  if (lat == null || lng == null) return null;

  const rawName = (tags.name || '').trim();

  // İstersen listeyi büyütelim
  const badNames = new Set(['Kamp Alanı', 'Home', 'بيت', 'Picnic']);
  if (!rawName || badNames.has(rawName)) return null;

  // ✅ burası tek isim kaynağı: rawName
  const name = rawName;

  return {
    osm_type: el.type,
    osm_id: el.id,
    name,
    lat,
    lng,
    tags_json: JSON.stringify(tags),
  };
}


async function upsertElements(elements) {
  const stmt = db.prepare(`
    INSERT INTO camps(osm_type, osm_id, name, lat, lng, tags_json, updated_at)
    VALUES(@osm_type, @osm_id, @name, @lat, @lng, @tags_json, datetime('now'))
    ON CONFLICT(osm_type, osm_id) DO UPDATE SET
      name=excluded.name,
      lat=excluded.lat,
      lng=excluded.lng,
      tags_json=excluded.tags_json,
      updated_at=datetime('now')
  `);

  const runMany = db.transaction((rows) => {
    for (const r of rows) stmt.run(r);
  });

  const rows = elements.map(elementToRow).filter(Boolean);
  runMany(rows);
  return rows.length;
}

async function enrichGeocodeForLatest(limit = 40) {
  // city/district/address boş olanlardan en güncel ilk N taneyi reverse ile doldur
  const items = db.prepare(`
    SELECT id, lat, lng FROM camps
    WHERE (city IS NULL OR city='') OR (address IS NULL OR address='')
    ORDER BY updated_at DESC
    LIMIT ?
  `).all(limit);

  for (const it of items) {
    const g = await reverseGeocode(it.lat, it.lng);
    db.prepare(`
      UPDATE camps SET city=?, district=?, address=?, updated_at=datetime('now')
      WHERE id=?
    `).run(g.city, g.district, g.address, it.id);
  }
}

// GET /api/camps?bbox=minLat,minLng,maxLat,maxLng
router.get('/', async (req, res) => {
  try {
    const bb = parseBbox(req.query.bbox);
    if (!bb) return res.status(400).json({ error: 'bbox gerekli: minLat,minLng,maxLat,maxLng' });

    const elements = await fetchCampsByBbox(bb);
    await upsertElements(elements);

    // reverse geocode doldur
    await enrichGeocodeForLatest(40);

    const rows = db.prepare(`
      SELECT id, name, lat, lng, tags_json, osm_type, osm_id, city, district, address, updated_at
      FROM camps
      WHERE lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?
      ORDER BY updated_at DESC
      LIMIT 300
    `).all(bb.minLat, bb.maxLat, bb.minLng, bb.maxLng);

    const out = rows.map(r => ({
      ...r,
      tags: JSON.parse(r.tags_json || '{}'),
    }));

    res.json(out);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error', detail: String(e) });
  }
});

// GET /api/camps/city?name=Istanbul
router.get('/city', async (req, res) => {
  try {
    const name = (req.query.name || '').toString().trim();
    if (!name) return res.status(400).json({ error: 'name gerekli' });

    const bbox = await searchCityBbox(name);
    if (!bbox) return res.status(404).json({ error: 'city_not_found' });

    // Aynı işlemi bbox ile yap
    //const elements = await fetchCampsByBbox(bbox);
   // await upsertElements(elements);
   // await enrichGeocodeForLatest(40);

    const rows = db.prepare(`
      SELECT id, name, lat, lng, tags_json, osm_type, osm_id, city, district, address, updated_at
      FROM camps
      WHERE lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?
      ORDER BY updated_at DESC
      LIMIT 500
    `).all(bbox.minLat, bbox.maxLat, bbox.minLng, bbox.maxLng);

    const out = rows.map(r => ({
      ...r,
      tags: JSON.parse(r.tags_json || '{}'),
    }));

    res.json({
      cityQuery: name,
      cityDisplay: bbox.displayName,
      bbox: { minLat: bbox.minLat, minLng: bbox.minLng, maxLat: bbox.maxLat, maxLng: bbox.maxLng },
      items: out,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error', detail: String(e) });
  }
});

module.exports = router;
