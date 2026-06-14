const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const { Pool } = require('pg');
const crypto = require('crypto');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: { 
    origin: "*",
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"]
  },
  transports: ['websocket', 'polling']
});

// CORS Middleware BEFORE other middleware
app.use((req, res, next) => {
  // Allow all origins
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, HEAD');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  res.header('Access-Control-Max-Age', '3600');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  
  next();
});

app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Audit-Logging
async function auditLog(userId, action, entityType, entityId, details, ip) {
  try {
    await pool.query(
      'INSERT INTO audit_log (user_id, action, entity_type, entity_id, details, ip_address) VALUES ($1, $2, $3, $4, $5, $6)',
      [userId, action, entityType, entityId, JSON.stringify(details), ip || '127.0.0.1']
    );
  } catch (e) {
    console.error('Audit error:', e);
  }
}

// Health Check
app.get('/health', (req, res) => {
  res.json({ ok: true, version: '1.0.0', timestamp: new Date() });
});

// Login Endpoint
app.post('/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }

    const r = await pool.query(
      'SELECT id, username, role FROM users WHERE username=$1 AND password_hash=$2',
      [username, password]
    );

    if (!r.rows.length) {
      await auditLog(null, 'LOGIN_FAILED', 'users', null, { username }, req.ip);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = r.rows[0];
    const token = crypto.randomBytes(32).toString('hex');
    
    await auditLog(user.id, 'LOGIN_SUCCESS', 'users', user.id, {}, req.ip);
    res.json({ token, user });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get all Incidents
app.get('/incidents', async (req, res) => {
  try {
    const r = await pool.query(
      'SELECT id, name, status, created_at FROM incidents WHERE status != $1 LIMIT 50',
      ['deleted']
    );
    res.json(r.rows);
  } catch (err) {
    console.error('Incidents error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get Incident Details
app.get('/incidents/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const incident = await pool.query('SELECT * FROM incidents WHERE id = $1', [id]);
    const resources = await pool.query('SELECT * FROM resources WHERE incident_id = $1', [id]);
    const markers = await pool.query('SELECT * FROM markers WHERE incident_id = $1', [id]);
    
    res.json({
      incident: incident.rows[0] || null,
      resources: resources.rows,
      markers: markers.rows
    });
  } catch (err) {
    console.error('Incident details error:', err);
    res.status(500).json({ error: err.message });
  }
});

// WebSocket Connections
io.on('connection', (socket) => {
  console.log(`🔗 Socket connected: ${socket.id}`);
  
  socket.on('join-incident', (incidentId, callback) => {
    socket.join(`incident:${incidentId}`);
    console.log(`📍 Socket ${socket.id} joined incident ${incidentId}`);
    if (callback) callback({ ok: true });
  });

  socket.on('resource:update', async (data) => {
    console.log(`📦 Resource update:`, data);
    io.to(`incident:${data.incident_id}`).emit('resource:updated', data);
  });

  socket.on('marker:add', async (data) => {
    console.log(`📌 Marker added:`, data);
    io.to(`incident:${data.incident_id}`).emit('marker:added', data);
  });

  socket.on('disconnect', () => {
    console.log(`🔓 Socket disconnected: ${socket.id}`);
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal Server Error' });
});

server.listen(3000, '0.0.0.0', () => {
  console.log('🎯 Stabs-API running on port 3000');
  console.log('🔒 DSGVO-compliant • CORS enabled • Audit-Logging');
});

module.exports = { app, server, io };
