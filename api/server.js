const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const http = require('http');
const { Server } = require('socket.io');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

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
  next()
});

// JWT Auth middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.sendStatus(401);

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// Socket.io connection handler
io.on('connection', (socket) => {
  console.log(`[Socket.io] Client connected: ${socket.id}`);

  // Handle document upload
  socket.on('document:upload', (data) => {
    console.log(`[Socket.io] Document upload: ${data.filename}`);
    socket.emit('document:uploading', { status: 'processing' });
  });

  // Handle document extraction
  socket.on('document:extract', (data) => {
    console.log(`[Socket.io] Document extract: ${data.document_id}`);
    socket.emit('document:extracting', { status: 'processing' });
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    console.log(`[Socket.io] Client disconnected: ${socket.id}`);
  });

  // Handle errors
  socket.on('error', (error) => {
    console.error(`[Socket.io] Error from ${socket.id}:`, error);
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Login endpoint (for testing)
app.post('/auth/login', (req, res) => {
  const token = jwt.sign({ user_id: 'demo-user' }, process.env.JWT_SECRET, {
    expiresIn: '24h',
  });
  res.json({ token });
});

// Protected routes
app.get('/api/health', authenticateToken, (req, res) => {
  res.json({ status: 'authenticated', user_id: req.user.user_id });
});

// Document upload endpoint
app.post('/api/documents/upload', authenticateToken, async (req, res) => {
  try {
    const { file_data, file_name } = req.body;
    
    if (!file_data || !file_name) {
      return res.status(400).json({ error: 'Missing file_data or file_name' });
    }

    // TODO: Save to database and trigger OCR
    res.json({
      success: true,
      message: 'Document uploaded successfully',
      filename: file_name,
      status: 'processing',
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Document extraction endpoint
app.post('/api/documents/extract', authenticateToken, async (req, res) => {
  try {
    const { document_id } = req.body;
    
    if (!document_id) {
      return res.status(400).json({ error: 'Missing document_id' });
    }

    // TODO: Call OCR service and return extracted data
    res.json({
      success: true,
      document_id,
      extracted_data: {
        firstName: '',
        lastName: '',
        dateOfBirth: '',
        confidence: {},
      },
      status: 'pending',
    });
  } catch (error) {
    console.error('Extraction error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: err.message });
});

// Server startup
server.listen(PORT, () => {
  console.log(`🚀 API Server running on http://localhost:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`WebSocket: ws://localhost:${PORT}`);
});

module.exports = { app, server, io };
