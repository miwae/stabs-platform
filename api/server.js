const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const http = require('http');
const { Server: SocketIOServer } = require('socket.io');

dotenv.config();

const app = express();
const httpServer = http.createServer(app);
const io = new SocketIOServer(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: false,
  },
  transports: ['websocket', 'polling'],
  allowEIO3: true,
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Serve static files
app.use(express.static('public'));

// Database pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Logger middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// JWT Auth middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.sendStatus(401);

  jwt.verify(token, process.env.JWT_SECRET || 'test-secret', (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// ============ REST API ROUTES ============

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    service: 'stabs-api',
    version: '2.0.0-dev'
  });
});

// Login endpoint (for testing)
app.post('/auth/login', (req, res) => {
  const token = jwt.sign(
    { user_id: 'demo-user', username: 'demo' }, 
    process.env.JWT_SECRET || 'test-secret',
    { expiresIn: '24h' }
  );
  res.json({ 
    success: true,
    token,
    user: { username: 'demo', role: 'user' }
  });
});

// Protected routes
app.get('/api/health', authenticateToken, (req, res) => {
  res.json({ 
    status: 'authenticated', 
    user_id: req.user.user_id,
    timestamp: new Date().toISOString()
  });
});

// Mock incidents endpoint
app.get('/api/incidents', authenticateToken, (req, res) => {
  res.json([
    { id: 1, name: 'Einsatz A', status: 'active' },
    { id: 2, name: 'Einsatz B', status: 'planning' }
  ]);
});

// ============ SOCKET.IO ============

io.on('connection', (socket) => {
  console.log(`[Socket.io] ✅ Client connected: ${socket.id}`);

  // Join incident room
  socket.on('join-incident', (incidentId) => {
    socket.join(`incident-${incidentId}`);
    console.log(`[Socket.io] User joined incident ${incidentId}`);
    socket.emit('joined-incident', { incidentId, status: 'joined' });
  });

  // Document upload
  socket.on('document:upload', (data) => {
    console.log(`[Socket.io] Document upload: ${data.filename}`);
    socket.emit('document:uploading', { status: 'processing', filename: data.filename });
  });

  // Document extraction
  socket.on('document:extract', (data) => {
    console.log(`[Socket.io] Document extract: ${data.document_id}`);
    socket.emit('document:extracting', { status: 'processing', document_id: data.document_id });
  });

  // Ping/Pong keep-alive
  socket.on('ping', () => {
    socket.emit('pong');
  });

  // Disconnect
  socket.on('disconnect', () => {
    console.log(`[Socket.io] ❌ Client disconnected: ${socket.id}`);
  });

  // Error handling
  socket.on('error', (error) => {
    console.error(`[Socket.io] Error from ${socket.id}:`, error);
  });
});

// ============ ERROR HANDLING ============

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: err.message });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ============ SERVER STARTUP ============

httpServer.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 API Server running on http://0.0.0.0:${PORT}`);
  console.log(`📡 WebSocket: ws://0.0.0.0:${PORT}`);
  console.log(`🏥 Health: http://0.0.0.0:${PORT}/health`);
  console.log(`🔌 Socket.io enabled with transports: websocket, polling\n`);
});

module.exports = { app, httpServer, io };
