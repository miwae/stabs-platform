# 🏢 STABS-PLATFORM ENTERPRISE ARCHITECTURE v3.0

## VISION: Vollständiger Ersatz für Eurocommand

Stabs-Platform als **offene, dezentralisierte, selbstgehostete** Alternative zu proprietären Einsatzleitung-Systemen mit:
- ✅ Offline-Funktionalität
- ✅ DRK-Server Integration
- ✅ Netzwerk-Mesh für Feldgeräte
- ✅ USB-Portable Installation
- ✅ Verschlüsselte Backups
- ✅ Offline-Kartendaten
- ✅ Enterprise-Grade Security

---

## 🏗️ ENTERPRISE DEPLOYMENT ARCHITEKTUR

### Szenario 1: Dezentralisierte Leitstelle (Offline-Ready)

```
┌─────────────────────────────────────────────────────────────┐
│ STABS-PLATFORM LEITSTELLE (USB-Portable)                   │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ PostgreSQL + PostGIS (Embedded)                      │  │
│ │ ├─ Offline-ready Datenbank                           │  │
│ │ ├─ 500MB-1GB lokale Kartendaten                      │  │
│ │ └─ DRK-Server Sync (bei Verbindung)                  │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ Stabs-API (Node.js + Express)                        │  │
│ │ ├─ REST Endpoints                                    │  │
│ │ ├─ Socket.io Real-Time                              │  │
│ │ └─ DRK-Server Bridge (REST API)                      │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ Vue.js 3 Frontend                                    │  │
│ │ ├─ Offline Mode (Service Worker)                     │  │
│ │ ├─ Offline-Karten (Leaflet Tiles)                    │  │
│ │ └─ Lokale Cache (IndexedDB)                          │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                              │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ Backup System (USB)                                  │  │
│ │ ├─ Verschlüsselte Datenbank-Dumps (GPG)             │  │
│ │ ├─ Auto-Backup alle 30 min                          │  │
│ │ └─ External Drive Mount: /mnt/backup                │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                              │
│ [USB-Drive: 32GB-128GB SSD mit eigenständigem Linux]       │
└─────────────────────────────────────────────────────────────┘
         ↕ (nur bei Internet-Verbindung)
┌─────────────────────────────────────────────────────────────┐
│ DRK-SERVER (Cloud/Zentral)                                  │
│ ├─ Betroffenen-Daten (Xenios-Ersatz)                        │
│ ├─ Bundesweite Suchanfragen                                 │
│ ├─ REST API: /api/drk-server/*                             │
│ └─ Verschlüsselte Sync (TLS 1.3)                            │
└─────────────────────────────────────────────────────────────┘
```

### Szenario 2: Verteilte Feldgeräte (Mesh-Netzwerk)

```
┌──────────────────────────────────────────────────────────┐
│ LEITSTELLE (Stabs-Platform Server)                       │
│ ├─ Primary Database (PostgreSQL)                         │
│ └─ Redis Pub/Sub (Mesh-Hub)                             │
└──────────────────────────────────────────────────────────┘
         ↓↓↓ (Mesh-Network: 4G, LoRa, Mesh-WLAN)
┌─────────────────────────────────────────────────────────┐
│ Feldgeräte (Tablets, Notebooks)                         │
│ ├─ Stabs-Client (Progressive Web App)                  │
│ ├─ Offline-Daten (50MB)                               │
│ ├─ Mesh-Router (Batman-adv / OLSR)                    │
│ └─ Auto-Sync bei Netzwerk                            │
└─────────────────────────────────────────────────────────┘
```

---

## 📱 OFFLINE-READY FEATURES

### Offline-Operationen (Keine Internet nötig)

✅ **Incident Management**
- Einsatzlagen erstellen/ändern
- Ressourcen-Positionen erfassen
- Marker setzen
- Polygone zeichnen

✅ **Karten-Darstellung**
- Offline-Karten (Leaflet + mbTiles)
- Aktuell bis vor 48h (cached)
- Satelliten-Ansicht (einmalig cached)
- Zoom 0-19

### Online-Sync Features

🔄 **Auto-Sync bei Reconnect**
- Konflikt-Prüfung (Last-Write-Wins)
- Sequential Replay
- DRK-Server Sync (bei verfügbar)

---

## 🔐 DRK-SERVER INTEGRATION

### Wichtig: Xenios wird abgelöst!

Xenios ist eine veraltete Lösung und wird durch eine Erweiterung von **DRK-Server** ersetzt (2024).

**Stabs-Platform sollte sich auf DRK-Server fokussieren!**

### DRK-Server REST API Integration

```
POST /api/drk-bridge/person
{
  "name": "Max Mustermann",
  "status": "wounded",
  "location": "Markthalle",
  "incident_id": "evt_2026_06_14_001"
}

GET /api/drk-bridge/search?query=MaxMustermann
→ Bundesweite Suchanfrage (mit Betroffenendaten)
```

---

## 💾 BACKUP-SYSTEM

### Automatische Verschlüsselte Backups

```
Schedule: Alle 30 Minuten
Destination: External USB Drive (/mnt/backup)
Encryption: GPG (2048-bit RSA + AES-256)
Retention: 90 Tage

Backup-File:
backup_2026-06-14_09-30_encrypted.sql.gpg
```

### Backup-Script

```bash
#!/bin/bash
BACKUP_DIR="/mnt/backup"
DB_USER="stabs_user"

# Dump + Encrypt
docker-compose exec postgres pg_dump -U $DB_USER stabs_db | gzip | \
  gpg --encrypt --recipient drk-backup-key > \
  "$BACKUP_DIR/backup_$(date +%Y-%m-%d_%H-%M)_encrypted.sql.gpg"

# Cleanup
find $BACKUP_DIR -name "backup_*_encrypted.sql.gpg" -mtime +90 -delete
```

---

## 🖥️ USB-PORTABLE INSTALLATION

### Boot-Medium Erstellung

```bash
# 1. Partitionierung
parted /dev/sdb mklabel gpt
parted /dev/sdb mkpart ESP fat32 1MiB 512MiB
parted /dev/sdb mkpart primary ext4 512MiB 100%

# 2. Ubuntu Live + Stabs-Platform
git clone https://github.com/miwae/stabs-platform /mnt/stabs/

# 3. Docker-Compose ready
cp docker-compose.yml /mnt/stabs/
```

### Boot-Prozess (30 Sekunden)

```
[1] USB Boot (10s) → BIOS → GRUB → Ubuntu Kernel
[2] Persistent Overlay (5s) → Filesystem ready
[3] Docker Start (10s) → PostgreSQL, Redis, API
[4] Frontend (5s) → Nginx Start
= 30 Sekunden → Production-Ready!
```

---

## 🔌 NETZWERK-MESH FÜR FELDGERÄTE

### Mesh-Technologie-Optionen

```
1. LoRaWAN
   - Range: 10-20km
   - Bandbreite: 50-250 kbps
   - Ideal für ländliche Gebiete

2. 4G/LTE Fallback
   - Range: bis zu Netzabdeckung
   - Bandbreite: 10-100 Mbps

3. Mesh-WLAN (Batman-adv)
   - Range: 100-500m pro Knoten
   - Bandbreite: 1-54 Mbps

4. Hybrid: LoRaWAN + 4G
   - Intelligentes Routing
   - Fallback-Hierarchie
```

---

## 🛡️ ENTERPRISE SECURITY

### Encryption at Rest

```
PostgreSQL
├─ PGCRYPTO (Sensitive Columns)
├─ Encrypt: passwords, personal data, audit logs
└─ LUKS Disk Encryption (USB-Drive)

Backups
├─ GPG Encryption (RSA 2048 + AES-256)
├─ DRK-Zertifikat Integration
└─ Offline Backup Keys (USB-Stick)
```

### Encryption in Transit

```
API ← HTTPS/TLS 1.3
├─ Let's Encrypt (auto-renew)
└─ HSTS Headers

WebSocket ← WSS (Secure WebSocket)
└─ TLS 1.3

DRK-Server ← Mutual TLS (mTLS)
├─ Client Cert: Leitstelle-Identifikation
└─ Server Cert: DRK-Server
```

---

## 📊 DEPLOYMENT ROADMAP

### Phase 1 (Juni-Juli 2026)
```
✅ Core Offline-Mode (v2.0.0)
✅ Encrypted Backups
✅ DRK-Server API Integration (Basic)
🔜 USB-Portable Installation
```

### Phase 2 (Juli-August 2026)
```
🔜 Full Offline-Maps (Germany + borders)
🔜 Mesh-Network Support (LoRaWAN)
🔜 Advanced Backup Management
🔜 USB Boot Medium
```

### Phase 3 (September-Dezember 2026)
```
🔜 Mobile Apps (iOS/Android)
🔜 DRK-Server Full Integration
🔜 Advanced Mesh-Routing
🔜 Field Testing + Validation
```

### Phase 4 (2027)
```
🔜 Enterprise-Scale Deployment
🔜 Multi-Leitstelle Synchronisation
🔜 Voice/Radio Integration
🔜 Predictive Analytics
```

---

## 🎯 SUCCESS CRITERIA

✅ Vollständiger **Offline-Betrieb** (keine Internet nötig)  
✅ **DRK-Server Integration** (Betroffenen-Datenbank)  
✅ **Verschlüsselte Backups** (automatisch, täglich)  
✅ **USB-Portable** (Boot in 30 Sekunden)  
✅ **Offline-Kartendaten** (aktuell, Satellit)  
✅ **Mesh-Network** (Feldgeräte-Vernetzung)  
✅ **Mobile Apps** (iOS/Android)  
✅ **Zero Vendor Lock-in** (Open-Source)  
✅ **DSGVO-Compliance** (Audit-Logging)  
✅ **Enterprise-Ready** (Skalierbar, Sicherheit)

---

**Version:** 3.0 — Enterprise  
**Status:** Specification Complete  
**Next:** Development Start  
**Target:** Production Q4 2026
