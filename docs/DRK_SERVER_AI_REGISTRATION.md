# 🔄 DRK-SERVER INTEGRATION & KI-BASIERTE REGISTRIERKARTEN-ERFASSUNG

**Advanced Integration & AI Concept**  
**Target:** Stabs-Platform v2.0.0 Phase 2+  
**Tech Stack:** DRK-Server REST API, Google Vision API, DeepSeek NER, n8n Automation  

---

## 1️⃣ XENIOS FUNKTIONEN & SCHNITTSTELLEN (LEGACY)

### Was Xenios leistet (Wird durch DRK-Server ersetzt!)

**3 Hauptfunktionen:**

#### A) Betroffenen-Registrierung
- Name, Vorname, Geburtsdatum
- Status: O (Unverletzt), V (Verletzt), T (Verstorben), Obdachlos
- Wohnort/Fundort
- Notizen
- Ereignis-Zuordnung

#### B) Suchanfragen
- Suchender + Gesuchte Person
- Status-Tracking (pending → found → closed)
- Abgleich mit Betroffenen-DB
- Benachrichtigungen bei Treffer

#### C) Multi-KAB Vernetzung
- Kreisauskunftsbüros verbinden
- Bundesweite Suchanfragen
- Ortsübergreifender Datenaustausch

### Xenios Schnittstellen (❌ NICHT nutzen!)

**Probleme:**
- ❌ Keine modernen APIs (REST/JSON)
- ❌ Proprietäre Java-Serialisierung
- ❌ Keine externe API-Dokumentation
- ❌ Legacy/Support eingestellt

---

## 2️⃣ DRK-SERVER INTEGRATION (✅ EMPFOHLEN!)

### Aktueller Status (2026)

| Aspekt | Status |
|--------|--------|
| **Zukunftslösung** | ✅ Offizielle DRK-Strategie |
| **API-Verfügbarkeit** | ✅ Seit Dezember 2023 (JSON-RPC 2.0) |
| **Endpunkte** | ✅ 100+ bereits entwickelt |
| **Weiterentwicklung** | ✅ Aktiv (Feb 2025: neue Endpoints) |
| **Dokumentation** | ✅ Abrufbar (mit drkserver Login) |

### API Architektur

```
Protokoll:     JSON-RPC 2.0
Auth:          API-Key (KV-spezifisch)
Dokumentation: https://www.drkserver.org/ (Login)
Hauptendpunkt: /api/persons, /api/events, /api/search-queries
```

### Wichtigste Endpoints

```
POST   /api/persons/create          — Person registrieren
GET    /api/persons/{id}            — Person abrufen
PUT    /api/persons/{id}            — Person aktualisieren
GET    /api/persons/search?q=...    — Bundesweite Suche

POST   /api/events/register         — Ereignis (Katastrophe) anlegen
GET    /api/events/{id}             — Ereignis-Details
GET    /api/events/{id}/persons     — Alle Betroffenen

POST   /api/search-queries/create   — Suchanfrage registrieren
PUT    /api/search-queries/{id}/status  — Status aktualisieren

GET    /api/kab/network             — KAB-Verbündelung
POST   /api/kab/sync                — Daten synchronisieren
```

---

## 3️⃣ KI-BASIERTE REGISTRIERKARTEN-ERFASSUNG (SMART WORKFLOW)

### Vision: Automatisierte Handschrift-Registrierung

```
Handgeschriebene Registrierkarte
         ↓ (Scanner)
Digitale Bilddatei
         ↓ (Google Vision OCR)
Extrahierter Text + Strukturdaten
         ↓ (DeepSeek NER)
Strukturierte Entitäten (Name, Geburtsdatum, Status...)
         ↓ (Fuzzy Matching)
Abgleich gegen DRK-Server Betroffenen-DB
         ↓ (Entscheidungslogik)
Automatische Erstellung oder Manuelles Review
         ↓ (DRK-Server API)
Datensatz in DRK-Server erstellt/aktualisiert
         ↓ (Operator-Überprüfung)
Finale Übernahme ins System
```

### 4.1 OCR + Handschrifterkennung

#### **Empfohlene Lösung: Google Cloud Vision API**

```
Genauigkeit:    ~95% (Drucktext), ~85-90% (Handschrift)
Kosten:         ~$0.50 pro Seite
Deutsch:        ✅ Vollständig unterstützt
Struktur:       ✅ JSON-Response (strukturiert)
Handschrift:    ✅ Exzellent für Registrierkarten
```

#### **API Request Beispiel**

```javascript
const vision = require('@google-cloud/vision');
const client = new vision.ImageAnnotatorClient({
  keyFilename: process.env.GOOGLE_VISION_KEY
});

async function extractFromRegistrationCard(imageBuffer) {
  const request = {
    image: { content: imageBuffer },
    features: [
      { type: 'DOCUMENT_TEXT_DETECTION' },  // Volltext
      { type: 'TEXT_DETECTION' }             // Handschrift
    ],
    imageContext: {
      languageHints: ['de']
    }
  };
  
  const [result] = await client.documentTextDetection(request);
  return result;
}
```

### 4.2 Named Entity Recognition (NER)

#### **DeepSeek für Strukturierung**

```javascript
// Nach OCR: Roher Text
const ocrText = `
Max Mustermann
geb. 12.03.1985
Wohnort: Berlin
Status: Verletzt
Notizen: Leichte Verletzung am Bein
`;

// DeepSeek Prompt
const prompt = `
Extrahiere folgende Felder aus der Registrierkarte:
- firstName: Vorname
- lastName: Nachname
- dateOfBirth: Geburtsdatum (YYYY-MM-DD)
- location: Wohnort
- status: enum(unwounded, wounded, deceased, missing)
- notes: Notizen

Text:
${ocrText}

Response: JSON nur
`;

// Response
{
  "firstName": "Max",
  "lastName": "Mustermann",
  "dateOfBirth": "1985-03-12",
  "location": "Berlin",
  "status": "wounded",
  "notes": "Leichte Verletzung am Bein",
  "confidence": {
    "firstName": 0.98,
    "lastName": 0.97,
    "dateOfBirth": 0.95,
    "location": 0.92,
    "status": 0.99
  }
}
```

### 4.3 Fuzzy Matching (Datenabgleich)

```javascript
// Datenabgleich gegen DRK-Server
async function findExistingPerson(extracted) {
  // 1. Exakte Suche
  const response = await drkApi.searchPersons({
    firstName: extracted.firstName,
    lastName: extracted.lastName,
    dateOfBirth: extracted.dateOfBirth
  });
  
  if (response.exact_match) {
    return { found: true, person: response.person, confidence: 1.0 };
  }
  
  // 2. Fuzzy Matching (Levenshtein Distance)
  const candidates = response.similar_matches || [];
  const matches = candidates
    .filter(p => levenshteinDistance(
      `${extracted.firstName} ${extracted.lastName}`,
      `${p.firstName} ${p.lastName}`
    ) / Math.max(...names.map(s => s.length)) > 0.85)
    .sort((a, b) => b.similarity - a.similarity);
  
  if (matches.length > 0) {
    return { found: true, person: matches[0], confidence: matches[0].similarity };
  }
  
  return { found: false };
}
```

---

## 5️⃣ n8n AUTOMATION WORKFLOW

### Workflow: "Smart Registration Karten-Erfassung"

```
🔴 TRIGGER: File Upload (registrierkaarten/*.jpg)
         ↓
🔵 IMAGE SCALING: 300 DPI für OCR-Optimierung
         ↓
🟢 GOOGLE VISION API: Text + Handschrift extrahieren
         ↓
🟣 DEEPSEEK NER: Strukturieren & Entitäten extrahieren
         ↓
🟡 DRK-SERVER SEARCH: Abgleich (Fuzzy Matching)
         ↓
🔴 DECISION: High Confidence → Auto-Create
                    OR Manual Review
         ↓
🟢 DRK-SERVER CREATE/UPDATE: Person registrieren
         ↓
🟡 NOTIFICATION: Slack/Email Alert
         ↓
🔵 LOGGING: Audit Trail
```

### n8n Node-Konfiguration

```yaml
# Node 1: File Trigger
Type: File Trigger
Path: ./uploads/registrierkaarten/
Extensions: jpg, png
Poll: 5 minutes

# Node 2: Image Processing
Type: Execute Command
Command: convert ${filename} -quality 95 -density 300 -depth 8 ${output}

# Node 3: Google Vision OCR
Type: HTTP Request
Method: POST
URL: https://vision.googleapis.com/v1/images:annotate?key=${GOOGLE_VISION_API_KEY}
Body:
  requests:
    - image:
        content: ${base64_image}
      features:
        - type: DOCUMENT_TEXT_DETECTION
        - type: TEXT_DETECTION

# Node 4: DeepSeek NER
Type: DeepSeek MCP
Model: deepseek-chat
Messages:
  - role: system
    content: "Extract registration card fields as JSON"
  - role: user
    content: "From this OCR text, extract: ${ocr_text}"

# Node 5: DRK-Server Search
Type: HTTP Request
Method: GET
URL: https://drkserver.de/api/persons/search
Params:
  q: "${firstName} ${lastName} ${dateOfBirth}"
Headers:
  Authorization: Bearer ${DRK_API_KEY}

# Node 6: Decision Logic
Type: Switch Node
Cases:
  Case 1: confidence > 0.95 AND !duplicate
    → Continue to Node 7 (Auto-Create)
  Case 2: ELSE
    → Continue to Node 8 (Manual Review Alert)

# Node 7: Auto-Create in DRK-Server
Type: HTTP Request
Method: POST
URL: https://drkserver.de/api/persons/create
Body: ${extracted_entities}

# Node 8: Manual Review Notification
Type: Slack Message
Channel: #registrierungen
Message: "Person ${firstName} ${lastName} needs manual review"

# Node 9: Logging
Type: PostgreSQL
Query: INSERT INTO ocr_log (...) VALUES (...)
```

---

## 6️⃣ KOSTENKALKULATION

### Pro Monat: 1000 Registrierkarten

| Service | Kosten/Unit | Monatlich |
|---------|---|---|
| Google Vision API | $0.50/Karte | $500 |
| DeepSeek API | $0.005/Karte | $5 |
| DRK-Server API | — | $0 |
| n8n Cloud | — | $50 |
| Hosting | — | $20 |
| **Total** | — | **$575** |

**Pro Registrierung:** $0.58  
**vs. Manuell:** $2-5  
**Einsparung:** 75-85%

---

## 7️⃣ ROADMAP

| Phase | Timeline | Ziel |
|-------|----------|------|
| 1 | Jul-Aug 2026 | Prototype (Google Vision + DeepSeek) |
| 2 | Sep-Oct 2026 | DRK-Server Integration + Fuzzy Matching |
| 3 | Nov-Dec 2026 | Production Deployment + UAT |

---

## 8️⃣ NEXT STEPS

### Sofort
- [ ] DRK Generalsekretariat kontaktieren → API-Zugang anfordern
- [ ] Google Vision API aktivieren (Key vorhanden!)
- [ ] n8n Workflow Prototype bauen

### Nächste 2 Wochen
- [ ] DeepSeek NER integrieren
- [ ] 10 Registrierkarten Test-Scan
- [ ] DRK-Server API Playground

### Nächste 6 Wochen
- [ ] Live mit echten Karten testen
- [ ] Manual Review Feedback loop
- [ ] Optimierung & Finetuning

---

**Status:** Konzept Abgeschlossen  
**Owner:** @miwae + DRK Partners  
**Target:** v2.0.0 Phase 2 (Q4 2026)
