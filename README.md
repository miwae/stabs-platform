# 🎯 Stabs-Platform

**Open-Source Alternative zu Eurocommand CommandX** — Digitale Einsatzleitung für Katastrophenschutz & BOS

## Features

✅ **Real-Time Multi-User** — WebSocket-basierte Echtzeit-Synchronisierung  
✅ **Lagekarte** — Leaflet.js mit OpenStreetMap Integration  
✅ **Ressourcen-Management** — Fahrzeuge, Personal, Standorte  
✅ **Taktische Symbole** — NATO-Symbole & Marker  
✅ **DSGVO-konform** — Audit-Logging, Verschlüsselung, Datenschutz  
✅ **HTTPS/TLS** — Let's Encrypt, sichere Kommunikation  
✅ **Automatische Backups** — Täglich, 30 Tage Aufbewahrung  
✅ **Docker** — PostgreSQL + Redis + Node.js API  

## Tech-Stack

| Component | Technology |
|-----------|------------|
| **Frontend** | Vue.js 3 + Leaflet.js |
| **API** | Node.js + Express + Socket.io |
| **Database** | PostgreSQL 16 + PostGIS |
| **Cache** | Redis 7 |
| **Web Server** | Nginx + Let's Encrypt |
| **Container** | Docker + Docker Compose |

## Quick Start

### 1️⃣ Manuelles Deployment

```bash
# Auf dem Server:
sudo bash -c "
  cd /home
  git clone https://github.com/miwae/stabs-platform.git
  cd stabs-platform
  bash deployment.sh planungs-tool.de miwae@outlook.de
"
```

### 2️⃣ Automatisches Deployment (GitHub Actions)

Secrets im GitHub Repo einrichten:
- `DEPLOY_KEY` — SSH Private Key (root@server)
- `SERVER_IP` — Server IP-Adresse

Dann jeder Push zu `main` triggert automatisches Deployment!

### 3️⃣ Docker Compose (Lokal)

```bash
# .env anlegen
cp .env.example .env

# Starten
docker-compose up -d

# Browser
http://localhost:3000/health
```

## Zugriff

```
🌐 https://planungs-tool.de/stabs/
👤 Username: demo
🔐 Password: demo123
```

## Administration

### Health Check
```bash
/usr/local/bin/stabs-health.sh
```

### Backup manuell
```bash
/usr/local/bin/stabs-backup.sh
```

### Logs
```bash
docker-compose logs api
docker-compose logs postgres
```

### Datenbank
```bash
docker-compose exec postgres psql -U stabs_user -d stabs_db
```

## Struktur

```
stabs-platform/
├── api/                          # Node.js API
│   ├── server.js                # Express + Socket.io
│   ├── package.json             # Dependencies
│   └── Dockerfile               # Container Image
├── frontend/
│   └── index.html               # Vue.js + Leaflet UI
├── docker-compose.yml           # Container Orchestration
├── init.sql                      # Database Schema
├── deployment.sh                # Deployment Script
├── .github/workflows/deploy.yml # GitHub Actions
└── README.md                    # Diese Datei
```

## DSGVO-Compliance

### Verarbeitete Daten
- Benutzerdaten (Username, gehashtes Passwort)
- Einsatzlagen (Name, Status, Beschreibung)
- Ressourcen (Fahrzeuge, Personal, Koordinaten)
- Audit-Log (Änderungen, Zeitstempel, IP-Adressen)

### Sicherheitsmaßnahmen
- ✅ HTTPS/TLS 1.3
- ✅ Passwort-Hashing (bcrypt)
- ✅ Audit-Logging (90 Tage)
- ✅ Automatische Backups
- ✅ Zugriffskontrolle (User-Permissions)
- ✅ Keine Drittländertransfer

### Betroffenenrechte
- **Auskunft** (Art. 15): michael@katschutz.local
- **Berichtigung** (Art. 16): UI oder Email
- **Löschung** (Art. 17): Email mit Begründung
- **Export** (Art. 20): JSON-Export via Datenbank

## Lizenz

MIT License — Open Source für KatSchutz/BOS Einsätze

## Autor

**Michael Waechter** — KatSchutz Emsland  
📧 miwae@outlook.de  
🌐 https://katschutz.local

## Support

- 📋 Issues: https://github.com/miwae/stabs-platform/issues
- 💬 Discussions: https://github.com/miwae/stabs-platform/discussions
- 📚 Wiki: https://github.com/miwae/stabs-platform/wiki

---

**Version:** 1.0.0 (Production Ready)  
**Letzte Aktualisierung:** Juni 2026  
**Status:** 🟢 Stabil

