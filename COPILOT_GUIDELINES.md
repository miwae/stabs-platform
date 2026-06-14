# Stabs-Platform Development Guidelines für GitHub Copilot

## Architektur

```
Frontend (Vue.js 3)
  ├─ Components
  ├─ Views
  └─ Stores (State Management)

API (Node.js + Express)
  ├─ Routes (/auth, /incidents, /resources, /markers)
  ├─ Middleware (CORS, Auth, Audit-Logging)
  └─ Controllers

Database (PostgreSQL + PostGIS)
  ├─ Users, Incidents, Resources
  ├─ Markers, Sessions
  └─ Audit-Log

WebSocket (Socket.io)
  ├─ Real-Time Synchronization
  └─ Room-based Broadcasting
```

## Code Standards

### Backend (Node.js)
```javascript
// ✅ Async/Await + Error Handling
app.post('/api/endpoint', async (req, res) => {
  try {
    const data = await pool.query(sql, params);
    await auditLog(userId, 'ACTION', 'entity', id, {}, req.ip);
    res.json(data.rows);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ✅ CORS Headers
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  next();
});

// ✅ Audit-Logging für DSGVO
await auditLog(userId, 'LOGIN_SUCCESS', 'users', user.id, {}, req.ip);
```

### Frontend (Vue.js 3)
```javascript
// ✅ Composition API
import { ref, onMounted } from 'vue';

const doLogin = async () => {
  try {
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(login.value)
    });
    const data = await res.json();
    if (data.error) {
      error.value = data.error;
      return;
    }
    user.value = data.user;
  } catch (e) {
    error.value = e.message;
  }
};
```

## v2 Features

- [ ] Polygon Drawing auf Lagekarte
- [ ] Route Planning
- [ ] GeoJSON Import/Export
- [ ] Offline Mode
- [ ] Resource GPS Tracking
- [ ] Incident Reports (PDF)
- [ ] Mobile App
- [ ] SMS Notifications
- [ ] CAD Integration

## Security & DSGVO

✅ HTTPS/TLS  
✅ CORS  
✅ SQL Injection Prevention  
✅ Audit-Logging  
✅ Data Encryption  

## Copilot Prompts für v2

```
Schreib einen Node.js Endpoint für [Feature] mit:
- PostgreSQL Query mit Prepared Statements
- CORS Headers
- Audit Logging
- Error Handling
- JSON Response

Schreib Vue.js Component für [UI] mit:
- Composition API
- Error Handling
- Loading States
- Fetch zur API

Schreib Tests für [Function] mit:
- Success Case
- Error Cases
- Edge Cases
```

## Commits

```
feat(api): add feature name
fix(frontend): bug description
docs: documentation update
test(scope): add tests
perf: performance improvement
```

---

**v2 Development mit GitHub Copilot!** 🤖

