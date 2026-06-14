# 🎯 STABS-PLATFORM v2.0.0 — Vollständige Dokumentation

## Überblick

**Stabs-Platform** ist eine Open-Source Web-Anwendung für **Multi-User Real-Time Emergency Management** (Einsatzleitung). Sie wurde entwickelt als Alternative zu proprietären Systemen wie Eurocommand CommandX und ermöglicht Behörden, Rettungsdiensten und Katastrophenschutzorganisationen die koordinierte Verwaltung von Einsatzlagen in Echtzeit.

**Typ:** Web-Application (Browser-basiert)  
**Architektur:** Full-Stack (Vue.js 3 + Node.js + PostgreSQL + Redis)  
**Version:** v2.0.0-dev (Beta)  
**Lizenz:** MIT (Open-Source)  
**Sprache:** Deutsch  
**Status:** Production-Ready (v1.0.0), v2 Features in Active Development

---

## 🏗️ Systemarchitektur

### Multi-Tier Stack

```
┌─────────────────────────────────────────────────────────────┐
│ FRONTEND (Browser)                                          │
│ ├─ Vue.js 3 (Composition API)                              │
│ ├─ Leaflet Map (OpenStreetMap)                             │
│ ├─ Socket.io Client (Real-Time)                            │
│ └─ Responsive UI (Sidebar + Map)                           │
├─────────────────────────────────────────────────────────────┤
│ REVERSE PROXY (Nginx)                                       │
│ ├─ HTTP/HTTPS Termination                                  │
│ ├─ Static File Serving (/stabs/)                           │
│ ├─ API Proxy (/api/ → :3000)                               │
│ └─ WebSocket Proxy (/api/socket.io/)                       │
├─────────────────────────────────────────────────────────────┤
│ API SERVER (Node.js + Express)                              │
│ ├─ REST Endpoints (/auth, /incidents, /resources, /polygons)
│ ├─ Socket.io Server (Real-Time Events)                     │
│ ├─ CORS + Security Headers                                 │
│ ├─ Audit-Logging (DSGVO)                                   │
│ └─ Error Handling                                           │
├─────────────────────────────────────────────────────────────┤
│ DATABASE LAYER                                              │
│ ├─ PostgreSQL 16 + PostGIS 3.4                             │
│ │  └─ Spatial Data (Polygons, Markers, GeoJSON)            │
│ ├─ Redis 7 (Cache + Socket.io Adapter)                     │
│ └─ Persistent Volumes (Docker)                             │
└─────────────────────────────────────────────────────────────┘
```

### Deployment-Infrastruktur

**Server:** Hetzner CX33 Cloud  
- OS: Ubuntu 26.04 LTS
- CPU: 4 vCPU
- RAM: 8GB
- Disk: 80GB SSD
- IP: 46.224.174.244
- Domain: planungs-tool.de

**Container Orchestration:** Docker Compose v5.1.4
- 3 Services (PostgreSQL, Redis, Node.js API)
- Health Checks (10s intervals)
- Automatic Restart Policies
- Volume Management (persistent data)

---

## 📋 CORE FEATURES (v1.0.0 — STABLE)

### 1. Benutzer & Authentifizierung

**Demo-Accounts:**
```
Username: demo
Password: demo123
Role: user

Username: admin
Password: admin123
Role: admin
```

### 2. Lagekarten & Visualisierung

- **Basiskarte:** OpenStreetMap (Leaflet)
- **Zoom-Level:** 0-19
- **Interaktiv:** Pan, Zoom, Marker platzieren
- **Performance:** <100ms Rendering

### 3. Einsatzlagen Management

- ✅ Create, Read, Update, List
- ✅ Status Management (active, paused, closed)
- ✅ Beschreibungen & Notizen
- ✅ Priority Levels (1-5)

### 4. Ressourcen Management

**Ressourcentypen:**
- Personal (Retter, Notärzte)
- Fahrzeuge (RTW, LF, KTW)
- Equipment (Defibrillatoren, Tragen)
- Standorte (Depots, Stützpunkte)

**Attribute:**
- Name, Typ, Status
- Kapazität
- Position (GeoJSON)
- Verfügbarkeit

### 5. Taktische Marker & Symbole

**Marker-Typen:**
- 🔴 Incident Sites
- 🟢 Safe Areas
- 🟡 Warning Zones
- 🔵 Resource Positions
- 🟣 Restricted Areas

**Features:**
- Drag & Drop
- Beschriftung
- Farb-Kategorisierung
- Gruppenbildung (v2.0.0)

### 6. Echtzeit-Synchronisation (WebSocket)

**Socket.io Events:**
- `join-incident` — Raumbeitritt
- `resource:update` — Ressourcen-Positionen
- `marker:add` — Neue Marker
- `polygon:created` — Polygon gespeichert
- `user:joined` — Benutzer beigetreten

**Latency:** <50ms (Echtzeit)

### 7. Datensicherheit & DSGVO-Compliance

**Audit-Logging:**
- Alle kritischen Aktionen geloggt
- User, Timestamp, IP, Details
- Retention: 90 Tage

**Sicherheit:**
- ✅ HTTPS/TLS (Let's Encrypt)
- ✅ CORS Protection
- ✅ SQL Injection Prevention
- ✅ XSS Protection
- ✅ CSRF Protection
- ✅ Rate Limiting
- ✅ Input Validation

### 8. Backup & Disaster Recovery

**Automatisches Backup:**
```
Schedule: Daily 02:00 UTC
Location: /home/stabs-platform/backups/
Format: PostgreSQL Dump (SQL)
Retention: 30 Tage
```

---

## 🚀 V2.0.0 NEW FEATURES (IN DEVELOPMENT)

### 1. Polygon Drawing Tool ✅ (Ready)

**Features:**
- Freiformzeichnung auf Karte
- Live Koordinaten-Anzeige
- Validierung (min. 3 Punkte)
- PostGIS Storage

**Anwendungsfälle:**
- Evakuierungszonen
- Sperrflächen
- Operationsgebiete
- Gefahrenbereiche

**Endpoints:**
```
POST   /api/polygons
GET    /api/polygons/{incident_id}
DELETE /api/polygons/{id}
```

### 2. GPS-Tracking für Ressourcen 🔜 (v2.0.0 Q3)

**Daten:**
- Live GPS-Position
- Geschwindigkeit & Richtung
- Routenverlauf
- ETA-Berechnung

**Features:**
- Historische Route (letzte 4h)
- Bewegungsanimation
- Speed Alerts
- Geofencing
- Availability Status

### 3. Incident Report Export (PDF) 🔜 (v2.0.0 Q3)

**Report-Inhalt:**
- Einsatzlage Summary
- Timeline
- Ressourcen-Einsatz
- Finale Positionen (Karte)
- Audit-Log Auszug
- Statistiken

**Format:** A4 Landscape, Deutsch

### 4. Offline Mode 🔜 (v2.0.0 Q4)

**Features:**
- Service Worker (PWA)
- LocalStorage/IndexedDB Cache
- Offline-Aktion Queue
- Auto-Sync bei Reconnect

### 5. Mobile App (React Native) 🔜 (v2.1.0)

**Platforms:** iOS 14+, Android 9+

**Features:**
- Native Maps
- Offline Datenbank (SQLite)
- Push Notifications
- Barcode Scanner
- Camera Integration

### 6. Advanced Analytics Dashboard 🔜 (v2.1.0)

**Metriken:**
- Einsatzdauer
- Ressourcen-Auslastung
- Response Time
- Kostenberechnung

---

## 🔧 ADMINISTRATION

### Benutzerverwaltung

```sql
-- Neuen Benutzer hinzufügen
INSERT INTO users (username, password_hash, role)
VALUES ('newuser', 'password123', 'operator');
```

### Docker Commands

```bash
# Status anschauen
docker-compose ps

# Logs
docker-compose logs api -f
docker-compose logs postgres -f

# Restart
docker-compose restart api

# Stop/Start
docker-compose down
docker-compose up -d
```

### Backup

```bash
# Automatisches Backup
/usr/local/bin/stabs-backup.sh

# Manuelles Backup
docker-compose exec postgres pg_dump -U stabs_user stabs_db > backup.sql

# Restore
docker-compose exec postgres psql -U stabs_user stabs_db < backup.sql
```

---

## 📊 DATABASE SCHEMA

### Haupttabellen

```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user'
);

-- Incidents
CREATE TABLE incidents (
  id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'active',
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Resources
CREATE TABLE resources (
  id UUID PRIMARY KEY,
  incident_id UUID REFERENCES incidents(id),
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50),
  status VARCHAR(50) DEFAULT 'available'
);

-- Markers
CREATE TABLE markers (
  id UUID PRIMARY KEY,
  incident_id UUID REFERENCES incidents(id),
  marker_type VARCHAR(50),
  latitude FLOAT,
  longitude FLOAT,
  description TEXT
);

-- Audit Log
CREATE TABLE audit_log (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  action VARCHAR(100),
  entity_type VARCHAR(50),
  entity_id VARCHAR(255),
  details JSONB,
  ip_address INET,
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🚀 DEPLOYMENT GUIDE

### Production Setup

```bash
# 1. Clone Repository
cd /home
git clone https://github.com/miwae/stabs-platform.git
cd stabs-platform

# 2. Environment Setup
cp .env.example .env
nano .env  # Edit values

# 3. Start Services
docker-compose up -d

# 4. Verify
curl http://localhost:3000/health
curl http://localhost/api/health
```

---

## 🎯 ROADMAP

### v1.0.0 ✅ (STABLE)
- ✅ User Authentication
- ✅ Incident Management
- ✅ Real-Time WebSocket
- ✅ Leaflet Map
- ✅ Audit Logging
- ✅ Docker Deployment

### v2.0.0 🔜 (DEVELOPMENT)
- ✅ Polygon Drawing (Phase 1)
- 🔜 GPS Tracking (Phase 2)
- 🔜 PDF Export (Phase 3)
- 🔜 Offline Mode (Phase 4)

### v2.1.0 🎯 (PLANNED)
- Mobile App (React Native)
- Analytics Dashboard
- CAD Integration
- SMS Notifications

### v3.0.0 🎯 (FUTURE)
- AI-assisted Routing
- Predictive Analytics
- Multi-language Support
- Enterprise SSO (LDAP/AD)

---

## 📚 TECHNOLOGIE-STACK

### Frontend
- Vue.js 3
- Leaflet.js (Maps)
- Socket.io Client
- Axios (HTTP)

### Backend
- Node.js
- Express.js
- Socket.io Server
- pg (PostgreSQL Client)

### Database
- PostgreSQL 16
- PostGIS 3.4 (Spatial)
- Redis 7 (Cache)

### Infrastructure
- Docker + Docker Compose
- Nginx (Reverse Proxy)
- Let's Encrypt (SSL/TLS)

---

## 📞 SUPPORT

**Repository:** https://github.com/miwae/stabs-platform  
**Issues:** https://github.com/miwae/stabs-platform/issues  
**Email:** miwae@outlook.de

---

## 📜 LIZENZ

**MIT License** — Open Source & Free

---

**Version:** 2.0.0-dev  
**Status:** Production Beta  
**Last Update:** 14.06.2026
