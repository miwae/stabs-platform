# 🔍 XENIOS DOWNLOAD & EXPLORATION GUIDE

## Status: XENIOS IS LEGACY SOFTWARE

Xenios wird **NICHT mehr unterstützt** und ist in der Ablösung durch **DRK-Server** (2024+).

---

## Wo kann man Xenios finden?

### Option 1: Legacy Software Archives
- **Software.informer.com**
  - https://xenios-datenerfassung-und-auswertung.software.informer.com/
  - Versionen: 2.0, 3.0
  - Status: Archiviert (2018)

- **UpdateStar.com**
  - https://xenios-datenerfassung-und-auswertung.updatestar.com/de
  - Historische Versionen
  - Download-Status: ❓ (oft nicht mehr verfügbar)

### Option 2: DRK Kontakt (EMPFOHLEN) ⭐
**Direkt beim DRK anfragen:**
- **DRK Generalsekretariat** (Offizieller Support)
- **DRK-Suchdienst**
  - https://www.drk-suchdienst.de
  - Email: suchdienst@drk.de
  - Tel: +49 228 975-0

- **Kreisverbände mit KAB (Kreisauskunftsbüro)**
  - Brandenburg an der Havel
  - Bayern
  - Nordrhein-Westfalen
  - (Viele haben noch funktionierende Xenios-Installationen!)

### Option 3: Sourceforge/GitHub Archives
- Suchen nach: `xenios DRK filetype:exe OR filetype:zip`
- ⚠️ **Warnung:** Sicherheitsrisiko! Legacy Software kann Malware enthalten.

---

## Technische Details

### Xenios 3.0 Spezifikationen
- **Programmiersprache:** Java
- **Runtime:** Java Virtual Machine (JRE 6.0+)
- **Executable:** javaw.exe
- **Database:** MySQL oder PostgreSQL
- **Protocol:** HTTP/HTTPS

### System-Anforderungen
```
OS: Windows XP/Vista/7/8/10
Java: JRE 6.0+
RAM: 512 MB minimum
Disk: 100 MB+
Network: TCP/IP
```

---

## Warum Xenios erkunden?

### ✅ Nützlich für:
1. **Reverse Engineering** — Datenstrukturen verstehen
2. **Schema-Mapping** — SQL-Schema für Betroffenen-Daten
3. **API-Design** — Welche Endpoints werden benötigt?
4. **UI/UX-Inspiration** — Benutzeroberfläche studieren
5. **Process Documentation** — Workflow verstehen

### ❌ Nicht nützlich für:
- Code kopieren (Legacy Java)
- Architecture übernehmen (veraltet)
- Direkter Support (wird nicht mehr entwickelt)

---

## Stabs-Platform Strategie (EMPFOHLEN)

### ➡️ Nicht: "Xenios Clone bauen"
- ❌ Legacy Technology (Java, alte DB)
- ❌ Kein Support vom DRK
- ❌ Keine Weiterentwicklung

### ✅ Stattdessen: "DRK-Server Bridge bauen"
- ✅ Offizielle DRK-Strategie (seit 2024)
- ✅ Modern APIs (REST/JSON)
- ✅ Active Development
- ✅ Zukunftssicher

---

## DRK-Server Integration (BETTER APPROACH)

### Schritt 1: DRK kontaktieren
```
An: Generalsekretariat@drk.de
Betreff: DRK-Server API Integration — Stabs-Platform

Benötigen:
- API-Dokumentation
- Test-Umgebung-Zugang
- OAuth2/mTLS Credentials
```

### Schritt 2: API-Dokumentation anfordern
- REST API Endpoints
- Authentication Methods
- Data Schema
- Rate Limits

### Schritt 3: Test-Integration bauen
```javascript
// DRK-Server Bridge Example

const drk = {
  async registerPerson(data) {
    return fetch(`https://drk-server.de/api/persons`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        firstName: data.firstName,
        lastName: data.lastName,
        status: data.status,  // unwounded, wounded, missing, deceased
        location: data.location,
        incident_id: data.incident_id
      })
    });
  },
  
  async searchPerson(query) {
    return fetch(
      `https://drk-server.de/api/search?q=${encodeURIComponent(query)}`,
      { headers: { 'Authorization': `Bearer ${token}` } }
    );
  }
};
```

---

## If You Want to Explore Xenios

### Sicher erkunden:

1. **Isolation:** Virtual Machine
   ```bash
   # Ubuntu 16.04 VM (isolated)
   java -jar xenios-3.0.jar
   ```

2. **Network-Isolation:** Host-only Network
   - Keine Internet-Verbindung

3. **Analysis Tools:**
   ```bash
   # Decompile
   cfr xenios-3.0.jar --outputdir=./src/
   
   # Database
   sqlite3 xenios.db ".schema"
   
   # Network
   wireshark -i eth0 -w capture.pcapng
   ```

---

## Expected Findings

### Database Schema (Annahme)
```sql
CREATE TABLE affected_persons (
  id INT PRIMARY KEY,
  event_id INT,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  date_of_birth DATE,
  status ENUM('uninjured', 'injured', 'deceased', 'missing'),
  location TEXT,
  notes TEXT
);

CREATE TABLE search_queries (
  id INT PRIMARY KEY,
  searcher_name VARCHAR(100),
  searched_person_name VARCHAR(100),
  status ENUM('pending', 'found', 'closed')
);
```

### UI Workflow
```
1. Ereignis erstellen
2. Betroffene registrieren
   - Name, Status, Standort
3. Suchanfragen registrieren
4. Abgleich (Matching)
5. Export/Reporting
6. Multi-KAB Sync
```

---

## Unser Roadmap für Stabs-Platform v2.0+

### Phase 1: DRK-Server API Integration
```
✅ REST API Wrapper
✅ Authentication
✅ Person Registration
✅ Search Queries
✅ Sync Logic
```

### Phase 2: Offline Mode
```
✅ Local SQLite
✅ Sync Queue
✅ Conflict Resolution
```

### Phase 3: Enterprise Scale
```
✅ Multi-Leitstelle Coordination
✅ Mesh Network
✅ Bundesweite Integration
```

---

## Fazit

✅ Xenios erkunden zum Verstehen  
❌ Nicht zum Code kopieren  
⭐ Besser: DRK kontaktieren für DRK-Server API!

---

## Links & Ressourcen

**DRK Official:**
- Suchdienst: https://www.drk-suchdienst.de
- Roter Kreis: https://roter-kreis.de/Xenios
- Generalsekretariat: https://www.drk.de

**GitHub:**
- Repository: https://github.com/miwae/stabs-platform

---

**Status:** Research Complete  
**Recommendation:** Contact DRK for DRK-Server API  
**Next:** Implement DRK-Server Bridge v2.0.0
