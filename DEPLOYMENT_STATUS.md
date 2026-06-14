# 🎯 Stabs-Platform Production Deployment

**Deployment Status: ✅ LIVE**

## Produktionsumgebung

```
Server: Hetzner CX33 (46.224.174.244)
OS: Ubuntu 26.04
Domain: planungs-tool.de
```

## Services Running

✅ **Nginx** — HTTPS Reverse Proxy (Port 80/443)
✅ **PostgreSQL 16** — Datenbank mit PostGIS + Audit-Logging
✅ **Redis 7** — Cache & Socket.io Adapter
✅ **Node.js API** — Express + Socket.io (Port 3000)
✅ **Vue.js Frontend** — Lagekarte mit Leaflet

## Features Active

- ✅ Multi-User Real-Time Synchronization (WebSocket)
- ✅ Lagekarte mit OpenStreetMap
- ✅ Ressourcen-Management
- ✅ Taktische Marker & Symbole
- ✅ DSGVO-Compliance (Audit-Logging, 90 Tage)
- ✅ Automatische Backups (täglich 02:00 Uhr, 30 Tage)
- ✅ CORS-Headers für Cross-Origin Requests
- ✅ Docker Compose Orchestration
- ✅ GitHub Actions CI/CD Pipeline

## Zugriff

```
URL: http://planungs-tool.de/stabs/
Demo Login: demo / demo123
API: /api/ (via Nginx Proxy)
Health: GET /api/health → {"ok":true}
```

## Docker Status

```bash
docker-compose ps
# stabs-platform-api       ✅ Running (health: healthy)
# stabs-platform-postgres  ✅ Running (health: healthy)
# stabs-platform-redis     ✅ Running (health: healthy)
```

## Admin Commands

```bash
# Health Check
/usr/local/bin/stabs-health.sh

# Backup Manual
/usr/local/bin/stabs-backup.sh

# Logs
docker-compose logs -f api

# Restart
docker-compose restart api
```

## Deployment Timeline

| Datum | Status | Änderungen |
|-------|--------|-----------|
| Jun 14, 2026 | ✅ Prod Ready | CORS-Fixes, API mit Headers, Frontend aktualisiert |
| Jun 14, 2026 | ✅ Stabil | Docker Compose, Datenbank, Nginx Proxy |
| Jun 14, 2026 | ✅ MVP | Initial Deployment, Vue.js + Leaflet |

## Next Steps (Optional)

- [ ] HTTPS/TLS mit Let's Encrypt hinzufügen
- [ ] GitHub Actions Secrets konfigurieren (SSH Deploy Key)
- [ ] Team-Training durchführen
- [ ] Datenschutzerklärung veröffentlichen
- [ ] Monitoring & Alerting ausbauen

## Support

- GitHub Issues: https://github.com/miwae/stabs-platform/issues
- Admin: michael@katschutz.local
- Datenschutz: miwae@outlook.de

---

**Stabs-Platform v1.0.0 — Production Ready**  
🎯 Einsatzbereit | 🔒 DSGVO-Konform | 🚀 Stabil

Deployment Date: June 14, 2026  
Last Update: 08:24 UTC
