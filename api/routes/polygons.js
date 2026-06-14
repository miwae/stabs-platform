const express = require('express');
const router = express.Router();

// POST /api/polygons - Create new polygon
router.post('/', async (req, res) => {
  const pool = req.app.get('db');
  const { incident_id, coordinates, type } = req.body;
  const user_id = req.user?.id || 1; // TODO: Extract from auth token

  // Validation
  if (!incident_id || !coordinates || coordinates.length < 3) {
    return res.status(400).json({
      error: 'incident_id and at least 3 coordinates required'
    });
  }

  try {
    // Convert coordinates to PostGIS polygon format
    // Format: ((lat1 lng1, lat2 lng2, ..., lat1 lng1))
    const coordsStr = coordinates
      .map(c => `${c.lng} ${c.lat}`)
      .join(', ');
    
    const closedCoords = coordsStr + (coordsStr !== '' ? `, ${coordinates[0].lng} ${coordinates[0].lat}` : '');
    const wktPolygon = `POLYGON((${closedCoords}))`;

    // Insert into database
    const result = await pool.query(
      `INSERT INTO markers (
        incident_id, 
        user_id, 
        marker_type, 
        latitude, 
        longitude, 
        description, 
        created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, NOW())
      RETURNING id, incident_id, marker_type, created_at`,
      [
        incident_id,
        user_id,
        'polygon',
        coordinates[0].lat, // Store first point for reference
        coordinates[0].lng,
        JSON.stringify({ type, coordinates, wkt: wktPolygon })
      ]
    );

    const polygon = result.rows[0];

    // Audit logging for DSGVO
    await pool.query(
      `INSERT INTO audit_log (user_id, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        user_id,
        'POLYGON_CREATED',
        'polygons',
        polygon.id,
        JSON.stringify({ incident_id, coordinates: coordinates.length }),
        req.ip || '127.0.0.1'
      ]
    );

    // Broadcast via WebSocket to all users in incident
    const io = req.app.get('io');
    io.to(`incident:${incident_id}`).emit('polygon:created', {
      id: polygon.id,
      incident_id,
      coordinates,
      type,
      created_by: user_id,
      created_at: polygon.created_at
    });

    res.status(201).json({
      id: polygon.id,
      incident_id,
      coordinates,
      type,
      created_at: polygon.created_at,
      message: 'Polygon created successfully'
    });

  } catch (err) {
    console.error('Polygon creation error:', err);
    res.status(500).json({
      error: 'Failed to create polygon',
      details: err.message
    });
  }
});

// GET /api/polygons/:incident_id - Get all polygons for incident
router.get('/:incident_id', async (req, res) => {
  const pool = req.app.get('db');
  const { incident_id } = req.params;

  try {
    const result = await pool.query(
      `SELECT id, incident_id, description, created_at, latitude, longitude
       FROM markers 
       WHERE incident_id = $1 AND marker_type = 'polygon'
       ORDER BY created_at DESC`,
      [incident_id]
    );

    const polygons = result.rows.map(row => ({
      id: row.id,
      incident_id: row.incident_id,
      created_at: row.created_at,
      ...JSON.parse(row.description)
    }));

    res.json(polygons);
  } catch (err) {
    console.error('Polygon fetch error:', err);
    res.status(500).json({
      error: 'Failed to fetch polygons',
      details: err.message
    });
  }
});

// DELETE /api/polygons/:id - Delete polygon
router.delete('/:id', async (req, res) => {
  const pool = req.app.get('db');
  const io = req.app.get('io');
  const { id } = req.params;
  const user_id = req.user?.id || 1;

  try {
    const result = await pool.query(
      'SELECT incident_id FROM markers WHERE id = $1 AND marker_type = $2',
      [id, 'polygon']
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: 'Polygon not found' });
    }

    const incident_id = result.rows[0].incident_id;

    // Delete polygon
    await pool.query('DELETE FROM markers WHERE id = $1', [id]);

    // Audit log
    await pool.query(
      `INSERT INTO audit_log (user_id, action, entity_type, entity_id, ip_address)
       VALUES ($1, $2, $3, $4, $5)`,
      [user_id, 'POLYGON_DELETED', 'polygons', id, req.ip || '127.0.0.1']
    );

    // Broadcast deletion
    io.to(`incident:${incident_id}`).emit('polygon:deleted', { id });

    res.json({ message: 'Polygon deleted successfully', id });

  } catch (err) {
    console.error('Polygon deletion error:', err);
    res.status(500).json({
      error: 'Failed to delete polygon',
      details: err.message
    });
  }
});

module.exports = router;
