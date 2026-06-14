# 🎯 STABS-Platform

**Multi-User Echtzeit-Einsatzleitung**
*Open-Source Alternative zu CommandX/Eurocommand für KatSchutz, BOS & Feuerwehr*

---

## 📋 Übersicht

STABS-Platform ist eine moderne, skalierbare Lösung für digitale Einsatzleitung und Lagekartenverwaltung. Entwickelt für:

- 🚨 **Katastrophenschutz (KatSchutz)**
- 🚒 **Feuerwehr & BOS**
- 🏥 **Rettungsdienste**
- 🛡️ **Ziviler Bevölkerungsschutz**

**Kernfeatures:**
- ✅ Multi-User WebSocket-Sync (Echtzeit)
- ✅ Lagekarte mit Leaflet.js
- ✅ Ressourcenverwaltung (Fahrzeuge, Personal)
- ✅ Symbologische Darstellung nach taktischen Zeichen
- ✅ Offline-Sync mit Konfliktauflösung
- ✅ PostGIS Geoindexing
- ✅ JWT-basierte Authentifizierung
- ✅ HTTPS-ready (Nginx Reverse Proxy)

---

## 🚀 Quick Start

### Automatisches Setup (Ubuntu 26.04)

```bash
curl -fsSL https://raw.githubusercontent.com/miwae/stabs-platform/main/setup-stabs.sh | sudo bash
```

Das Script installiert:
- Docker & Docker Compose
- PostgreSQL 16 mit PostGIS
- Redis 7
- Node.js API
- Nginx Reverse Proxy

**Nach ~10 Minuten:**
```
Browser: http://YOUR_SERVER_IP/stabs/
Login: demo / demo123
```

---

## 🏗️ Architektur

```
┌─────────────────────────────────────┐
│  Browser (Vue 3 + Leaflet)          │
│  WebSocket Client                   │
└────────────┬────────────────────────┘
             │ WSS/HTTPS
             ↓
┌─────────────────────────────────────┐
│  Nginx (Reverse Proxy)              │
│  Port 80/443 → localhost:3000       │
└────────────┬────────────────────────┘
             │
             ↓
┌─────────────────────────────────────┐
│  Node.js API + Socket.io            │
│  Port 3000 (Docker Container)       │
├──────────┬─────────────────────────┤
│ Express  │ Socket.io               │
│ REST API │ Multi-User Sync         │
└──────────┴─────────────────────────┘
             │
    ┌────────┴────────┐
    ↓                 ↓
┌──────────┐      ┌──────────┐
│ PostgreSQL│      │ Redis    │
│ PostGIS  │      │ Sessions │
│ Data     │      │ Pub/Sub  │
└──────────┘      └──────────┘
```

---

## 📁 Dateistruktur

```
stabs-platform/
├── setup-stabs.sh              # Automatisches Setup-Script
├── docker-compose.yml          # Docker Orchestration
├── init.sql                    # PostgreSQL Schema + Testdaten
├── api/
│   ├── Dockerfile              # Node.js Container
│   ├── package.json            # Dependencies
│   └── server.js               # Express + Socket.io API
└── README.md                   # Diese Datei
```

---

## 🔧 Manuelle Installation

Für Custom-Setups oder lokale Entwicklung:

```bash
# 1. Dependencies installieren
sudo apt-get update
sudo apt-get install -y docker.io docker-compose nginx postgresql-client-16

# 2. Repository clonen
git clone https://github.com/miwae/stabs-platform.git
cd stabs-platform

# 3. .env generieren
DB_PW=$(openssl rand -base64 24)
JWT_SEC=$(openssl rand -base64 32)

cat > .env << EOF
DB_PASSWORD=$DB_PW
JWT_SECRET=$JWT_SEC
NODE_ENV=production
PORT=3000
REDIS_URL=redis://redis:6379
DATABASE_URL=postgresql://stabs_user:$DB_PW@postgres:5432/stabs_db
EOF

# 4. Container starten
docker-compose up -d

# 5. Nginx konfigurieren
sudo cp nginx.conf /etc/nginx/sites-available/default
sudo systemctl reload nginx
```

---

## 📊 Datenbank-Schema

### Haupttabellen

**users** — Benutzer & Authentifizierung
```sql
id, username, password_hash, role (user|admin), email, full_name
```

**incidents** — Einsatzlagen
```sql
id, name, description, status (active|closed|deleted), created_by, version
```

**resources** — Ressourcen (Fahrzeuge, Personal)
```sql
id, incident_id, name, type, location (GEOGRAPHY), status, callsign, crew_count
```

**markers** — Taktische Zeichen
```sql
id, incident_id, symbol_type, location, label, color, size
```

**polygons** — Sperrgebiete, Evakuierungszonen
```sql
id, incident_id, name, type, geom (GEOGRAPHY)
```

---

## 🔐 Authentifizierung

### Login
```bash
POST /auth/login
{
  "username": "demo",
  "password": "demo123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 1,
    "username": "demo",
    "role": "user"
  }
}
```

JWT Token wird in `Authorization: Bearer <token>` gesendet.

---

## 🌐 REST API

### Incidents

```bash
# Alle Lagen abrufen
GET /incidents

# Spezifische Lage + Ressourcen + Marker
GET /incidents/:id

# Response:
{
  "incident": { id, name, status, created_at, version },
  "resources": [ { id, name, type, lat, lng, status } ],
  "markers": [ { id, symbol_type, lat, lng, label } ]
}
```

### Health Check
```bash
GET /health
```

---

## 📡 WebSocket Events

### Client → Server

```javascript
socket.emit('join-incident', incidentId, (response) => {
  console.log('Joined incident:', response.success);
});

socket.emit('resource:update', {
  id: 1,
  name: 'MTW-01',
  status: 'en-route',
  location: { lat: 51.1234, lng: 7.5678 }
});

socket.emit('marker:create', {
  symbol_type: 'friendly_unit',
  location: { lat: 51.12, lng: 7.56 },
  label: 'Sammelplatz'
});

socket.emit('cursor:move', {
  position: { lat: 51.12, lng: 7.56 }
});
```

### Server → Clients

```javascript
socket.on('resource:updated', (data) => {
  // Ressource auf Lagekarte aktualisieren
});

socket.on('marker:created', (data) => {
  // Neues Symbol anzeigen
});

socket.on('users-updated', (users) => {
  // Aktive User anzeigen
});

socket.on('cursor:moved', (data) => {
  // Cursor anderer User anzeigen
});
```

---

## 🚢 Deployment

### Docker Compose

```bash
cd /home/stabs-platform
docker-compose up -d        # Start
docker-compose ps           # Status
docker-compose logs -f api  # Logs
docker-compose restart api  # Restart
docker-compose down         # Stop
```

### Nginx Konfiguration

```nginx
location /stabs/ {
    proxy_pass http://localhost:3000/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_connect_timeout 7d;
    proxy_send_timeout 7d;
    proxy_read_timeout 7d;
}
```

---

## 👥 Standard-User

Nach Installation verfügbar:

| Username | Passwort | Rolle |
|----------|----------|-------|
| demo | demo123 | user |
| admin | admin123 | admin |

**⚠️ Passwörter nach Deployment ändern!**

---

## 🔄 Multi-User Sync

### Konfliktauflösung

Bei konkurrenten Änderungen nutzt STABS-Platform **Versionskontrolle**:

```
Client A: Ändert Resource v1 → v2
Server: Erhält v2, speichert

Client B: Ändert Resource v1 → v2 (gleichzeitig)
Server: v1 ≠ v2 Conflict! Sendet aktuellen State
Client B: Empfängt v2, merges lokal
```

### Offline-Sync

Änderungen werden in `sync_queue` gepuffert:
- Client geht offline
- Änderungen werden gequeued
- Client geht online
- Queue wird abgearbeitet
- Server & Client synced

---

## 📈 Performance

- **PostgreSQL PostGIS**: 1M+ Marker/Polygons
- **Redis Adapter**: Multi-Instance Skalierung
- **Socket.io**: 1000+ Concurrent Users
- **WebSocket Transports**: WebSocket + Polling Fallback

---

## 🛠️ Troubleshooting

### Container läuft nicht

```bash
cd /home/stabs-platform
docker-compose logs api      # API Logs
docker-compose logs postgres # DB Logs
docker-compose ps            # Status
```

### Passwort zurücksetzen

```bash
cd /home/stabs-platform
docker-compose exec postgres psql -U stabs_user -d stabs_db
UPDATE users SET password_hash = 'neues_passwort' WHERE username = 'demo';
```

### Port bereits in Benutzung

```bash
# Port 3000 freigeben
lsof -i :3000 | grep -v PID | awk '{print $2}' | xargs kill -9

# Oder anderen Port nutzen in docker-compose.yml:
# ports:
#   - "3001:3000"
```

---

## 📝 Lizenz

MIT License — Open Source für Katastrophenschutz & Öffentlicher Dienst

---

## 🤝 Contributing

Contributions sind willkommen! Issues & PRs:
https://github.com/miwae/stabs-platform

---

## 📞 Support

Für Fragen & Support:
- Issues: https://github.com/miwae/stabs-platform/issues
- Email: support@katschutz.local (Placeholder)

---

**Made with ❤️ for KatSchutz, BOS & Feuerwehr**

*Echtzeit-Einsatzleitung für den Ernstfall*
