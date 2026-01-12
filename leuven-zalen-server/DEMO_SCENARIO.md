# Demo Scenario: Leuven Zalen LDES Server

This scenario demonstrates the Linked Data Event Stream (LDES) server for publishing versioned information about Leuven's meeting rooms and halls.

## Demo Overview

**Duration**: 10-15 minutes
**Audience**: Colleagues interested in LDES, OSLO standards, or Linked Data
**Goal**: Show how LDES enables version-aware, standardized publication of public infrastructure data

## Scenario: Publishing Room Availability Data

Imagine you work for Stad Leuven and need to publish information about available meeting rooms and halls so that:
- Citizens can discover and book spaces
- Other systems can consume and integrate this data
- Historical changes are preserved (who changed what and when)
- Everything follows OSLO standards for interoperability

## Demo Script

### Part 1: The Problem (2 minutes)

**Talking Points:**
- Traditional APIs provide current state only - no history
- Different cities use different formats - no interoperability
- Updates require polling - inefficient for consumers
- No standardized vocabularies - integration is hard

**The LDES Solution:**
- Immutable event stream of all changes
- OSLO-compliant data models (Zaalreservatie, Cultuur & Jeugd Infrastructuur)
- Consumers replay history or sync incrementally
- Standard RDF/Turtle format, consumable by any Linked Data tool

### Part 2: Starting the Server (3 minutes)

**Demo Actions:**
```bash
# Start services
docker-compose up -d

# Show initialization
docker-compose logs -f ldes-server
# Wait for "Started Application" message

# Set up LDES stream
./setup-ldes.sh
```

**Talking Points:**
- LDES Server is open source (Informatievlaanderen)
- Uses PostgreSQL for storage
- Configurable fragmentation strategies (pagination, time-based, geospatial)
- We're using simple pagination for this demo

**Show the output:**
- Event stream created at `/zalen`
- Paginated view at `/zalen/by-page`
- Ready to ingest data

### Part 3: Understanding the Data Model (3 minutes)

**Show a sample data file:**
```bash
cat data/raadzaal.ttl
```

**Highlight key elements:**

1. **Versioned URIs with timestamps:**
   ```turtle
   <https://www.leuven.be/raadzaal#2026-01-12T10:00:00Z>
   ```

2. **Standard types:**
   ```turtle
   a schema:Place, infrastructure:Infrastructuurobject
   ```

3. **Versioning metadata:**
   ```turtle
   dcterms:isVersionOf <https://www.leuven.be/raadzaal>
   prov:generatedAtTime "2026-01-12T10:00:00Z"
   ```

4. **OSLO properties:**
   ```turtle
   zaalreservatie:beschikbaar true
   zaalreservatie:oppervlakte "180"
   infrastructure:faciliteiten "Audio-installatie", "Microfoons"
   ```

5. **Schema.org for discoverability:**
   ```turtle
   schema:name "Raadzaal"
   schema:maximumAttendeeCapacity 120
   schema:openingHours "Mo-Fr 09:00-22:00"
   ```

**Talking Points:**
- Every property is from a standard vocabulary
- Multilingual support (`"Raadzaal"@nl`)
- Rich structured addresses using OSLO Adres
- All facilities and amenities clearly described

### Part 4: Ingesting Data (2 minutes)

**Demo Actions:**
```bash
# Load all sample data
./ingest-data.sh
```

**Talking Points:**
- In production, this would be automated
- Could be triggered by CMS updates, database changes, or scheduled jobs
- Each POST creates a new immutable version
- Old versions never disappear - full audit trail

**Show the output:**
- 4 zalen successfully ingested
- Each represents a different type of venue:
  - Municipal administrative center
  - Historic council chamber
  - Cultural venue
  - Community center

### Part 5: Consuming the Stream (5 minutes)

#### A. View Stream Metadata
```bash
curl http://localhost:9003/zalen | head -50
```

**Talking Points:**
- This is the LDES entry point
- Describes the stream structure
- Points to available views (pagination)
- Declares the shape and versioning strategy

#### B. View Actual Data
```bash
curl http://localhost:9003/zalen/by-page?pageNumber=1
```

**Point out:**
- All 4 zalen on one page (page size is 50)
- Complete RDF data in Turtle format
- Each member includes all properties
- Can be consumed by any RDF library

#### C. Query Specific Properties
```bash
# Get just the names and capacities
curl -s http://localhost:9003/zalen/by-page?pageNumber=1 | \
  grep -E "schema:name|schema:maximumAttendeeCapacity"
```

**Results show:**
- Bosstraat Zaal 1: 50 people
- Raadzaal: 120 people
- Celestijntje: 80 people
- Vlierbeekveld Zaal: 100 people

### Part 6: The Power of Versioning (3 minutes)

**Scenario: Update a Room's Capacity**

Create a new version of Raadzaal with updated capacity:

```bash
cat > /tmp/raadzaal-updated.ttl << 'EOF'
@prefix schema: <https://schema.org/> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix locn: <http://www.w3.org/ns/locn#> .
@prefix adres: <https://data.vlaanderen.be/ns/adres#> .
@prefix infrastructure: <https://data.vlaanderen.be/ns/cultuur-en-jeugd/infrastructuur#> .
@prefix zaalreservatie: <https://data.vlaanderen.be/ns/zaalreservatie#> .

<https://www.leuven.be/raadzaal#2026-01-12T14:30:00Z>
  a schema:Place, infrastructure:Infrastructuurobject ;
  dcterms:isVersionOf <https://www.leuven.be/raadzaal> ;
  prov:generatedAtTime "2026-01-12T14:30:00Z"^^xsd:dateTime ;

  schema:name "Raadzaal"@nl ;
  schema:description "Historische raadzaal van Stad Leuven in het stadhuis. Capaciteit tijdelijk verhoogd voor speciale evenementen."@nl ;
  schema:maximumAttendeeCapacity "150"^^xsd:integer ;

  locn:address [
    a locn:Address ;
    locn:thoroughfare "Grote Markt" ;
    locn:locatorDesignator "9" ;
    adres:postcode "3000" ;
    adres:gemeentenaam "Leuven"@nl
  ] ;

  zaalreservatie:oppervlakte "180"^^xsd:decimal ;
  infrastructure:faciliteiten "Audio-installatie"@nl, "Microfoons"@nl, "Klimaatregeling"@nl ;
  schema:openingHours "Mo-Fr 09:00-22:00, Sa-Su 10:00-18:00" ;
  zaalreservatie:beschikbaar true ;
  schema:telephone "+32 16 27 20 00" ;
  schema:url <https://www.leuven.be/raadzaal> .
EOF

# Ingest the update
curl -X POST http://localhost:9003/zalen \
  -H "Content-Type: text/turtle" \
  --data-binary "@/tmp/raadzaal-updated.ttl"
```

**View the result:**
```bash
curl -s http://localhost:9003/zalen/by-page?pageNumber=1 | \
  grep "raadzaal" -A 3 | grep -E "generatedAtTime|maximumAttendeeCapacity"
```

**Talking Points:**
- Now TWO versions of Raadzaal exist
- Original: 120 capacity at 10:00:00
- Updated: 150 capacity at 14:30:00
- Both versions preserved forever
- Consumers can see what changed and when
- Perfect audit trail for compliance

### Part 7: Consumer Perspective (2 minutes)

**Show how consumers benefit:**

1. **Initial Sync:**
   - Consumer starts from page 1
   - Processes all members
   - Builds complete dataset

2. **Incremental Updates:**
   - Consumer bookmarks last processed timestamp
   - Polls for new pages
   - Only processes changes since last sync
   - Efficient and scalable

3. **Time Travel:**
   - Consumer can rebuild state at any point in history
   - "Show me all rooms as they were on January 1st"
   - Crucial for data analysis and compliance

4. **Interoperability:**
   - Standard RDF format
   - OSLO vocabularies everyone understands
   - Works with Apache Jena, RDFLib, Oxigraph, etc.
   - Can be imported into triple stores for SPARQL queries

## Demo Wrap-up

**Key Takeaways:**
1. LDES provides immutable, version-aware data publication
2. OSLO standards enable interoperability across Flanders
3. Simple HTTP + RDF = universal accessibility
4. Built-in audit trail for all changes
5. Efficient for producers and consumers

**Use Cases Beyond Rooms:**
- Cultural events (OSLO Cultureel Erfgoed)
- Road works and mobility (OSLO Mobiliteit)
- Environmental sensors (OSLO Sensor)
- Public services (OSLO Dienstverlening)
- Any domain with changing data that needs versioning

**Resources for Audience:**
- Full code: `leuven-zalen-server/` directory
- Setup scripts: `setup-ldes.sh`, `ingest-data.sh`
- Documentation: `README.md`, `QUICKSTART.md`
- LDES Spec: https://semiceu.github.io/LinkedDataEventStreams/
- OSLO: https://data.vlaanderen.be/

## Q&A Topics to Prepare

**Common Questions:**

1. **"How does this differ from a regular API?"**
   - API: current state only, custom format
   - LDES: full history, standard format, self-descriptive

2. **"What about performance?"**
   - Fragmentation strategies optimize delivery
   - Consumers cache locally
   - Only sync deltas after initial load
   - Scales horizontally

3. **"How do I protect sensitive data?"**
   - See `protected-setup/` example in parent directory
   - OAuth2 authentication
   - Granular access control per view
   - GDPR-compliant deletion possible via compaction

4. **"Can I query this data?"**
   - Yes! Load into triple store (GraphDB, Virtuoso)
   - Use SPARQL for complex queries
   - Or consume into your own database
   - LDES is transport, not query interface

5. **"What if my data model isn't in OSLO?"**
   - Can use any RDF vocabulary
   - Schema.org is widely supported
   - Create custom vocabularies if needed
   - OSLO provides best interoperability in Flanders

## Bonus: Live Updates Demo

If time permits, show a live update cycle:

```bash
# Terminal 1: Watch the stream
watch -n 2 'curl -s http://localhost:9003/zalen/by-page?pageNumber=1 | grep tree:member | wc -l'

# Terminal 2: Add updates
for i in {1..5}; do
  # Create new version with updated timestamp
  sed "s/10:00:00/10:0$i:00/g" data/bosstraat-zaal1.ttl | \
  curl -X POST http://localhost:9003/zalen \
    -H "Content-Type: text/turtle" \
    --data-binary @-
  sleep 2
done
```

Watch the member count increase in real-time!

---

**End of Demo Scenario**

Good luck with your demonstration! The combination of practical setup, clear explanation, and live updates makes LDES concepts tangible and compelling.
