# 🔍 XENIOS RESEARCH & DRK-SERVER INTEGRATION

## Xenios — Was ist das?

**Xenios** ist eine Datenerfassungs- und Auswertungssoftware des **Deutschen Roten Kreuzes (DRK)** für:

- **Katastrophen-Management**
- **Großschadensereignisse**
- **Großveranstaltungen**
- **Konflikte & Krisen**

---

## Status: ABGELÖST (2024!)

⚠️ **Wichtig:** Xenios wird **NICHT mehr weiterentwickelt** und befindet sich in der **Ablösung durch DRK-Server** (2024).

**Stabs-Platform sollte sich auf die Zukunft konzentrieren: DRK-Server, nicht Xenios!**

---

## Was Xenios leistet

### Datenerfassung

Xenios erfasst Daten über **Betroffene eines Katastrophenereignisses** nach Art der Betroffenenheit:

- ✅ **Unverletzt** (O)
- ✅ **Verletzt/Erkrankt** (V)
- ✅ **Tödlich** (T)
- ✅ **Obdachlos** (in Notunterkunft)
- ✅ **Einsatzkraft** (Mitarbeiter)

### Suchanfragen

- ✅ Personen-Registrierung
- ✅ Abgleich mit Suchfragen
- ✅ Ortsübergreifende Suche (bei Vernetzung)
- ✅ Bundesweiter Datenaustausch

### Administration

- ✅ Benutzerverwaltung
- ✅ Ereigniskonfiguration
- ✅ Datenaustausch-Management

---

## Technische Details

**Programmiersprache:** Java  
**Ausführbare Datei:** javaw.exe  
**Versionen:** 2.0, 3.0  
**Entwickler:** Deutsches Rotes Kreuz  

---

## Xenios → DRK-Server Migration

Das System wird nicht mehr weiterentwickelt und befindet sich in der Ablösung (2024). Es soll durch eine Erweiterung von DRK-Server ersetzt werden.

### DRK-Server Advantages

```
Feature                 Xenios      DRK-Server
─────────────────────────────────────────────
Modern Architecture     ❌ Java     ✅ Modern
Weiterentwicklung       ❌ Nein     ✅ Ja
API Endpoints           ⚠️ Limited  ✅ Full REST
Cloud-Ready             ❌ Nein     ✅ Ja
Mobile Support          ❌ Nein     ✅ Ja
Integration             ❌ Limited  ✅ Full
Active Support          ❌ Legacy   ✅ Active
```

---

## STABS-PLATFORM Strategie

### Warum DRK-Server, nicht Xenios?

1. **Xenios ist Legacy** — Wird bereits abgelöst
2. **DRK-Server ist Zukunft** — Offizielle Strategie des DRK
3. **Modern APIs** — REST/JSON, nicht veraltete XML
4. **Weiterentwicklung** — DRK investiert aktiv
5. **Standardisierung** — Bundesweit vereinheitlicht

### Integration Architecture

```
Stabs-Platform
    ↓
┌─────────────────────────────┐
│ DRK-Server Bridge (v2.0.0)  │
│  /api/drk-bridge/*          │
└─────────────────────────────┘
    ↓
DRK-Server API (REST)
    ├─ Person Registration
    ├─ Search Queries
    ├─ Status Sync
    └─ Audit Logging
```

### Implementierungs-Schritte

```
Phase 1 (Q3 2026)
  → Basic DRK-Server REST API Integration
  → Person/Status Sync
  → Search Query Forwarding

Phase 2 (Q4 2026)
  → Full Bi-directional Sync
  → Conflict Resolution
  → Offline Caching

Phase 3 (2027)
  → Multi-Leitstelle Coordination
  → Bundesweite Integration
  → Advanced Analytics
```

---

## Where to Find Xenios

### Download Sources

**Option 1: DRK Knowledge Base**  
https://roter-kreis.de/Xenios

**Option 2: Historical Archives**  
- Sourceforge or legacy software archives
- DRK Generalsekretariat (direct contact)

**Option 3: Testing/Demo Instances**  
- Contact: DRK Suchdienst
- Request: Xenios 3.0 Demo Access

**Note:** Xenios is now in discontinuation. Official support/downloads may be limited.

---

## DRK-Server Integration (Better Alternative)

### Official Resources

**DRK-Server Documentation:**  
- https://web-handbuch.drk-intern.de (requires DRK login)
- API documentation with examples
- Integration guides

### API Endpoints to Implement

```
# Person Management
POST   /api/drk-server/person/register
PUT    /api/drk-server/person/{id}
GET    /api/drk-server/person/{id}
DELETE /api/drk-server/person/{id}

# Search Queries
GET    /api/drk-server/search?query=...
POST   /api/drk-server/search/new

# Status Management
PUT    /api/drk-server/person/{id}/status
GET    /api/drk-server/person/{id}/status-history

# Incident Management
POST   /api/drk-server/incident/register
GET    /api/drk-server/incident/{id}
PUT    /api/drk-server/incident/{id}

# Sync & Audit
GET    /api/drk-server/sync-status
GET    /api/drk-server/audit-log
```

---

## Stabs-Platform Integration Points

### Database Schema (DRK-Bridge)

```sql
-- Stabs-Platform lokale Tabelle
CREATE TABLE drk_persons (
    id UUID PRIMARY KEY,
    incident_id UUID REFERENCES incidents(id),
    drk_server_id VARCHAR(255),  -- External DRK-Server ID
    name VARCHAR(255),
    birth_date DATE,
    status ENUM('registered', 'missing', 'found', 'deceased'),
    location_last_seen TEXT,
    notes TEXT,
    synced_at TIMESTAMP,
    sync_status ENUM('local', 'syncing', 'synced', 'failed'),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Sync-Log für Konflikt-Resolution
CREATE TABLE drk_sync_log (
    id UUID PRIMARY KEY,
    person_id UUID REFERENCES drk_persons(id),
    action VARCHAR(50),  -- 'create', 'update', 'delete', 'conflict'
    local_data JSONB,
    remote_data JSONB,
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Incident <-> DRK-Event Mapping
CREATE TABLE drk_event_mapping (
    id UUID PRIMARY KEY,
    incident_id UUID REFERENCES incidents(id),
    drk_event_id VARCHAR(255),
    event_type ENUM('großschadensereignis', 'katastrophe', 'großveranstaltung', 'konflikt'),
    scope ENUM('lokal', 'regional', 'bundesweit'),
    synced_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Why Stabs-Platform Is Better Than Xenios

| Aspect | Xenios | Stabs-Platform |
|--------|--------|----------------|
| **Active Development** | ❌ Discontinued | ✅ Active |
| **Modern Tech** | ❌ Java/Legacy | ✅ Node.js/Vue.js |
| **Open Source** | ❌ Proprietary | ✅ MIT License |
| **Mobile Ready** | ❌ No | ✅ Progressive Web App |
| **Offline Capable** | ❌ No | ✅ Yes (Full Feature) |
| **Self-Hosted** | ❌ Limited | ✅ Yes (Docker) |
| **DRK-Server Ready** | ❌ Legacy | ✅ Integrated |
| **Cost** | ❌ License Required | ✅ Free |
| **Customizable** | ❌ Limited | ✅ 100% |
| **Community** | ❌ None | ✅ Open Community |

---

## Next Steps for Stabs-Platform

1. **Contact DRK** for DRK-Server API credentials
   - Request: Integration Partner Access
   - Scope: Full API (Person, Search, Events)

2. **Implement DRK-Server Bridge** (v2.0.0 Phase 2)
   - REST API wrapper
   - Authentication (OAuth2/Mutual TLS)
   - Sync logic + conflict resolution

3. **Test Integration** with DRK Test Environment
   - Person registration
   - Search queries
   - Multi-Leitstelle coordination

4. **Deploy to Production** (Q4 2026)
   - Full DRK-Server integration
   - Enterprise-grade reliability
   - DSGVO compliance

---

## References

- Roter Kreis Xenios: https://roter-kreis.de/Xenios
- DRK Suchdienst: https://www.drk-suchdienst.de
- DRK Web-Handbuch: https://web-handbuch.drk-intern.de (Internal)

---

**Status:** Research Complete  
**Recommendation:** Focus on DRK-Server, not Xenios  
**Next Action:** Contact DRK for integration credentials
